import 'dotenv/config';
import cors from 'cors';
import express from 'express';
import pg from 'pg';
import OpenAI from 'openai';

const { Pool } = pg;
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

const app = express();
app.use(cors());
app.use(express.json());

const openai = process.env.OPENAI_API_KEY
  ? new OpenAI({ apiKey: process.env.OPENAI_API_KEY })
  : null;

/** Firebase ID token payload (dev: unverified decode). For production, verify with firebase-admin. */
function uidFromBearer(req) {
  const h = req.headers.authorization;
  if (!h?.startsWith('Bearer ')) return null;
  const token = h.slice(7);
  const parts = token.split('.');
  if (parts.length < 2) return null;
  try {
    const pad = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    const json = Buffer.from(pad, 'base64').toString('utf8');
    const payload = JSON.parse(json);
    return payload.user_id || payload.sub || null;
  } catch {
    return null;
  }
}

function requireUid(req, res) {
  const uid = uidFromBearer(req);
  if (!uid) {
    res.status(401).json({ error: 'Missing or invalid Authorization bearer token' });
    return null;
  }
  return uid;
}

app.post('/api/v1/stats/sync', async (req, res) => {
  const uid = requireUid(req, res);
  if (!uid) return;
  const { steps, workoutCalories, stepsCalories, workoutCount, date } = req.body || {};
  const d = (date || new Date().toISOString().split('T')[0]).slice(0, 10);
  try {
    await pool.query(
      `INSERT INTO daily_stats (firebase_uid, activity_date, steps, workout_calories, steps_calories, workout_count)
       VALUES ($1, $2::date, $3, $4, $5, $6)
       ON CONFLICT (firebase_uid, activity_date) DO UPDATE SET
         steps = EXCLUDED.steps,
         workout_calories = EXCLUDED.workout_calories,
         steps_calories = EXCLUDED.steps_calories,
         workout_count = EXCLUDED.workout_count`,
      [
        uid,
        d,
        Number(steps) || 0,
        Number(workoutCalories) || 0,
        Number(stepsCalories) || 0,
        Number(workoutCount) || 0,
      ],
    );
    res.json({ ok: true });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'sync_failed' });
  }
});

app.get('/api/v1/stats/daily', async (req, res) => {
  const uid = requireUid(req, res);
  if (!uid) return;
  const today = new Date().toISOString().split('T')[0];
  try {
    const { rows } = await pool.query(
      `SELECT steps, workout_calories, steps_calories, total_calories, workout_count
       FROM daily_stats WHERE firebase_uid = $1 AND activity_date = $2::date`,
      [uid, today],
    );
    if (!rows.length) return res.json(null);
    const r = rows[0];
    res.json({
      steps: r.steps,
      workoutCalories: Number(r.workout_calories),
      stepsCalories: Number(r.steps_calories),
      totalCalories: Number(r.total_calories),
      workoutCount: r.workout_count,
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'daily_failed' });
  }
});

app.get('/api/v1/stats/weekly', async (req, res) => {
  const uid = requireUid(req, res);
  if (!uid) return;
  const end = new Date();
  const start = new Date(end);
  start.setDate(end.getDate() - 6);
  try {
    const { rows } = await pool.query(
      `SELECT COALESCE(AVG(steps), 0)::float AS avg_steps,
              COALESCE(SUM(workout_count), 0)::int AS workout_count
       FROM daily_stats
       WHERE firebase_uid = $1 AND activity_date BETWEEN $2::date AND $3::date`,
      [uid, start.toISOString().split('T')[0], end.toISOString().split('T')[0]],
    );
    res.json({
      avgSteps: rows[0].avg_steps,
      workoutCount: rows[0].workout_count,
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'weekly_failed' });
  }
});

function heuristicReminders({ stepsToday, stepGoal, workoutsThisWeek }) {
  const behind = stepsToday < stepGoal * 0.5;
  const lowWorkouts = workoutsThisWeek < 2;
  let title = 'Fitness Freak nudge';
  let body = 'Take a 10-minute walk — your future self will thank you.';
  let hour = 18;
  let minute = 30;
  if (behind && lowWorkouts) {
    title = 'Double win today';
    body =
      'Steps are behind and workouts are light. Try a 15-minute brisk walk after lunch.';
    hour = 13;
    minute = 15;
  } else if (behind) {
    body = 'You are under half your step goal — a quick evening stroll will close the gap.';
    hour = 19;
    minute = 0;
  } else if (lowWorkouts) {
    body = 'Steps look good! Add one short strength or mobility session this week.';
    hour = 17;
    minute = 45;
  }
  return { title, body, suggestedHour: hour, suggestedMinute: minute, source: 'heuristic' };
}

app.post('/api/v1/reminders/suggest', async (req, res) => {
  const uid = requireUid(req, res);
  if (!uid) return;
  const { stepsToday = 0, stepGoal = 8000, workoutsThisWeek = 0 } = req.body || {};

  if (openai) {
    try {
      const completion = await openai.chat.completions.create({
        model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content:
              'You are a supportive fitness coach. Reply with JSON only: {"title":"","body":"","suggestedHour":0-23,"suggestedMinute":0-59}',
          },
          {
            role: 'user',
            content: JSON.stringify({
              stepsToday,
              stepGoal,
              workoutsThisWeek,
            }),
          },
        ],
        response_format: { type: 'json_object' },
      });
      const text = completion.choices[0]?.message?.content;
      if (text) {
        const parsed = JSON.parse(text);
        return res.json({
          title: parsed.title,
          body: parsed.body,
          suggestedHour: parsed.suggestedHour,
          suggestedMinute: parsed.suggestedMinute,
          source: 'openai',
        });
      }
    } catch (e) {
      console.error('openai_fallback', e);
    }
  }

  res.json(heuristicReminders({ stepsToday, stepGoal, workoutsThisWeek }));
});

const port = Number(process.env.PORT) || 3000;
app.listen(port, () => {
  console.log(`Fitness Freak API on :${port}`);
});
