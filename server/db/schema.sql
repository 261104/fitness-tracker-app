CREATE TABLE IF NOT EXISTS daily_stats (
  id SERIAL PRIMARY KEY,
  firebase_uid TEXT NOT NULL,
  activity_date DATE NOT NULL,
  steps INT NOT NULL DEFAULT 0,
  workout_calories REAL NOT NULL DEFAULT 0,
  steps_calories REAL NOT NULL DEFAULT 0,
  workout_count INT NOT NULL DEFAULT 0,
  total_calories REAL GENERATED ALWAYS AS (workout_calories + steps_calories) STORED,
  UNIQUE (firebase_uid, activity_date)
);

CREATE INDEX IF NOT EXISTS idx_daily_stats_uid_date ON daily_stats (firebase_uid, activity_date DESC);
