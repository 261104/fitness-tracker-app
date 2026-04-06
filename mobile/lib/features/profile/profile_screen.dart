import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../../providers/providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _goal = TextEditingController();
  bool _saving = false;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = ref.read(userProfileProvider).asData?.value ?? UserProfile.guest;
      if (!_seeded && mounted) {
        _height.text = p.heightCm.toStringAsFixed(0);
        _weight.text = p.weightKg.toStringAsFixed(0);
        _goal.text = p.dailyStepGoal.toString();
        _seeded = true;
      }
    });
  }

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    _goal.dispose();
    super.dispose();
  }

  String _initial(User? u) {
    final n = u?.displayName;
    if (n == null || n.isEmpty) return 'F';
    return n[0].toUpperCase();
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    final profile = UserProfile(
      displayName: user.displayName ?? 'Athlete',
      heightCm: double.tryParse(_height.text) ?? 170,
      weightKg: double.tryParse(_weight.text) ?? 70,
      dailyStepGoal: int.tryParse(_goal.text) ?? 8000,
    );
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(profile.toFirestore(), SetOptions(merge: true));
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.lavender,
              child: Text(
                _initial(user),
                style: const TextStyle(
                  color: AppColors.purple,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            title: Text(user?.displayName ?? kAppName),
            subtitle: Text(email),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _height,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Height (cm)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _weight,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Weight (kg) — used for calorie estimates',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _goal,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Daily step goal',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save profile'),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => ref.read(authServiceProvider).signOut(),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}
