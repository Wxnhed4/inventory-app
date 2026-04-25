import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../custom_drawer.dart';
import '../widgets/section_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const String routeName = '/profile';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'No email available';
    final uid = user?.uid ?? 'Unknown user';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      drawer: const CustomDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      foregroundColor: AppColors.primary,
                      child: const Icon(Icons.person_rounded, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kitchen operations account',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _InfoRow(label: 'User ID', value: uid),
                const SizedBox(height: 12),
                _InfoRow(label: 'Authentication', value: 'Firebase Email/Password'),
                const SizedBox(height: 12),
                _InfoRow(label: 'Role', value: 'Kitchen Manager'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SectionHeading(
                  title: 'Project Highlights',
                  subtitle:
                      'A quick summary of the app features you can point out during your presentation.',
                ),
                SizedBox(height: 16),
                _FeatureLine(
                  title: 'Authentication',
                  subtitle: 'Secure sign up, sign in, and password reset with Firebase Auth.',
                ),
                SizedBox(height: 12),
                _FeatureLine(
                  title: 'Inventory Control',
                  subtitle: 'Track ingredient quantities, search stock, and spot low-stock items.',
                ),
                SizedBox(height: 12),
                _FeatureLine(
                  title: 'Waste Monitoring',
                  subtitle: 'Record spoilage and review waste history for accountability.',
                ),
                SizedBox(height: 12),
                _FeatureLine(
                  title: 'Batch Tracking',
                  subtitle: 'Log production batches and automatically deduct ingredients.',
                ),
                SizedBox(height: 12),
                _FeatureLine(
                  title: 'Reports',
                  subtitle: 'See top wasted items and ingredient usage summaries.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _FeatureLine extends StatelessWidget {
  final String title;
  final String subtitle;

  const _FeatureLine({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.primary.withValues(alpha: 0.10),
          foregroundColor: AppColors.primary,
          child: const Icon(Icons.check_rounded, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
