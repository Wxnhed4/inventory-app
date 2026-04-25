import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../custom_drawer.dart';
import '../widgets/section_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const String routeName = '/dashboard';

  Future<_DashboardData> _loadDashboardData() async {
    final firestore = FirebaseFirestore.instance;
    final inventory = await firestore.collection('inventory').get();
    final waste = await firestore.collection('waste').get();
    final batches = await firestore.collection('batches').get();

    int lowStock = 0;
    final lowStockItems = <String>[];
    for (final doc in inventory.docs) {
      final data = doc.data();
      final quantity = (data['quantity'] as int?) ?? 0;
      if (quantity <= 5) {
        lowStock++;
        final name = data['name'] as String? ?? 'Unknown';
        final unit = data['unit'] as String? ?? '';
        lowStockItems.add('$name ($quantity $unit)');
      }
    }

    return _DashboardData(
      inventoryCount: inventory.docs.length,
      wasteCount: waste.docs.length,
      batchCount: batches.docs.length,
      lowStockCount: lowStock,
      lowStockItems: lowStockItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kitchen Overview',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      drawer: const CustomDrawer(),
      body: FutureBuilder<_DashboardData>(
        future: _loadDashboardData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final dashboardData = snapshot.data ??
              const _DashboardData(
                inventoryCount: 0,
                wasteCount: 0,
                batchCount: 0,
                lowStockCount: 0,
                lowStockItems: [],
              );

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Kitchen Operations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Monitor stock, waste, and production from one dashboard.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                shrinkWrap: true,
                childAspectRatio: 1.15,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _DashboardCard(
                    title: 'Inventory Items',
                    value: '${dashboardData.inventoryCount}',
                    icon: Icons.inventory_2_rounded,
                  ),
                  _DashboardCard(
                    title: 'Waste Records',
                    value: '${dashboardData.wasteCount}',
                    icon: Icons.delete_outline_rounded,
                    accentColor: AppColors.accent,
                  ),
                  _DashboardCard(
                    title: 'Batches',
                    value: '${dashboardData.batchCount}',
                    icon: Icons.precision_manufacturing_outlined,
                  ),
                  _DashboardCard(
                    title: 'Low Stock',
                    value: '${dashboardData.lowStockCount}',
                    icon: Icons.warning_amber_rounded,
                    accentColor: AppColors.error,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeading(
                      title: 'Attention Needed',
                      subtitle:
                          'These ingredients need restocking soon and look great in a demo as live operational insight.',
                    ),
                    const SizedBox(height: 16),
                    if (dashboardData.lowStockItems.isEmpty)
                      const EmptyStateView(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'No low-stock ingredients',
                        subtitle: 'Inventory levels look healthy right now.',
                      )
                    else
                      ...dashboardData.lowStockItems.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor:
                                      AppColors.error.withValues(alpha: 0.14),
                                  foregroundColor: AppColors.error,
                                  child: const Icon(
                                    Icons.priority_high_rounded,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _QuickActionTile(
                title: 'Manage Inventory',
                subtitle: 'Add, edit, and review stock items.',
                icon: Icons.inventory_rounded,
                routeName: '/inventory',
              ),
              const SizedBox(height: 12),
              _QuickActionTile(
                title: 'Record Waste',
                subtitle: 'Log spoilage, damage, and over-preparation.',
                icon: Icons.delete_sweep_rounded,
                routeName: '/waste',
              ),
              const SizedBox(height: 12),
              _QuickActionTile(
                title: 'Create Batch',
                subtitle: 'Track ingredients used for production.',
                icon: Icons.layers_outlined,
                routeName: '/batch',
              ),
              const SizedBox(height: 12),
              _QuickActionTile(
                title: 'View Reports',
                subtitle: 'See summaries of waste and usage.',
                icon: Icons.bar_chart_rounded,
                routeName: '/reports',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardData {
  final int inventoryCount;
  final int wasteCount;
  final int batchCount;
  final int lowStockCount;
  final List<String> lowStockItems;

  const _DashboardData({
    required this.inventoryCount,
    required this.wasteCount,
    required this.batchCount,
    required this.lowStockCount,
    required this.lowStockItems,
  });
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    this.accentColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: accentColor.withValues(alpha: 0.12),
              foregroundColor: accentColor,
              child: Icon(icon),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String routeName;

  const _QuickActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.10),
          foregroundColor: AppColors.primary,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.pushNamed(context, routeName),
      ),
    );
  }
}
