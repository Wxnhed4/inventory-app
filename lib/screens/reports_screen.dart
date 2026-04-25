import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../widgets/section_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final CollectionReference _waste = FirebaseFirestore.instance.collection(
    'waste',
  );
  final CollectionReference _batches = FirebaseFirestore.instance.collection(
    'batches',
  );

  DateTime? _startDate;
  DateTime? _endDate;

  Future<Map<String, Map<String, dynamic>>> _getWasteByIngredient() async {
    Query query = _waste;
    if (_startDate != null && _endDate != null) {
      query = query
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!),
          )
          .where(
            'timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(_endDate!),
          );
    }

    final snapshot = await query.get();
    final wasteByIngredient = <String, Map<String, dynamic>>{};
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final ingredient = data['itemName'] as String? ?? 'Unknown';
      final wastedQty = data['wastedQty'] as int? ?? 0;
      final unit = data['unit'] as String? ?? '';

      if (!wasteByIngredient.containsKey(ingredient)) {
        wasteByIngredient[ingredient] = {'quantity': 0, 'unit': unit};
      }
      wasteByIngredient[ingredient]!['quantity'] += wastedQty;
    }
    return wasteByIngredient;
  }

  Future<Map<String, Map<String, dynamic>>> _getBatchUsage() async {
    Query query = _batches;
    if (_startDate != null && _endDate != null) {
      query = query
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!),
          )
          .where(
            'timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(_endDate!),
          );
    }

    final snapshot = await query.get();
    final usageByIngredient = <String, Map<String, dynamic>>{};
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final ingredients = data['ingredients'] as List<dynamic>? ?? [];
      for (final item in ingredients) {
        final ingredient = item as Map<String, dynamic>;
        final name = ingredient['name'] as String? ?? 'Unknown';
        final used = ingredient['used'] as int? ?? 0;
        final unit = ingredient['unit'] as String? ?? '';

        if (!usageByIngredient.containsKey(name)) {
          usageByIngredient[name] = {'quantity': 0, 'unit': unit};
        }
        usageByIngredient[name]!['quantity'] += used;
      }
    }
    return usageByIngredient;
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  int _sumQuantities(Map<String, Map<String, dynamic>> data) {
    return data.values.fold<int>(
      0,
      (runningTotal, item) =>
          runningTotal + ((item['quantity'] as int?) ?? 0),
    );
  }

  String _topEntryLabel(Map<String, Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return 'None';
    }

    final sortedEntries = data.entries.toList()
      ..sort(
        (a, b) => ((b.value['quantity'] as int?) ?? 0)
            .compareTo((a.value['quantity'] as int?) ?? 0),
      );
    return sortedEntries.first.key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insights & Reports')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeading(
                    title: 'Operational Insights',
                    subtitle:
                        'Track waste and production activity with a focused date range.',
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _selectDateRange,
                    icon: const Icon(Icons.date_range_outlined),
                    label: Text(
                      _startDate != null && _endDate != null
                          ? '${DateFormat('yyyy-MM-dd').format(_startDate!)} to ${DateFormat('yyyy-MM-dd').format(_endDate!)}'
                          : 'Select Date Range',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, Map<String, dynamic>>>(
              future: _getWasteByIngredient(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final wasteByIngredient = snapshot.data ?? {};
                return Column(
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 220,
                          child: MetricTile(
                            label: 'Total Waste Qty',
                            value: '${_sumQuantities(wasteByIngredient)}',
                            icon: Icons.delete_outline_rounded,
                            color: AppColors.accent,
                          ),
                        ),
                        SizedBox(
                          width: 260,
                          child: MetricTile(
                            label: 'Top Wasted Item',
                            value: _topEntryLabel(wasteByIngredient),
                            icon: Icons.warning_amber_rounded,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildReportSection(
                      title: 'Waste by Ingredient',
                      subtitle:
                          'Ingredients are ranked by the amount lost during the selected period.',
                      data: wasteByIngredient,
                      emptyIcon: Icons.delete_sweep_outlined,
                      accentColor: AppColors.accent,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, Map<String, dynamic>>>(
              future: _getBatchUsage(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final batchUsage = snapshot.data ?? {};
                return Column(
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 220,
                          child: MetricTile(
                            label: 'Total Batch Usage',
                            value: '${_sumQuantities(batchUsage)}',
                            icon: Icons.precision_manufacturing_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(
                          width: 260,
                          child: MetricTile(
                            label: 'Top Used Ingredient',
                            value: _topEntryLabel(batchUsage),
                            icon: Icons.bar_chart_rounded,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildReportSection(
                      title: 'Batch Usage',
                      subtitle:
                          'Ingredients are ranked by how much production consumed them.',
                      data: batchUsage,
                      emptyIcon: Icons.layers_clear_outlined,
                      accentColor: AppColors.primary,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSection({
    required String title,
    required String subtitle,
    required Map<String, Map<String, dynamic>> data,
    required IconData emptyIcon,
    required Color accentColor,
  }) {
    final sortedEntries = data.entries.toList()
      ..sort(
        (a, b) => ((b.value['quantity'] as int?) ?? 0)
            .compareTo((a.value['quantity'] as int?) ?? 0),
      );

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(title: title, subtitle: subtitle),
          const SizedBox(height: 16),
          if (sortedEntries.isEmpty)
            SizedBox(
              height: 180,
              child: EmptyStateView(
                icon: emptyIcon,
                title: 'No data available',
                subtitle: 'Try another date range or add more activity data.',
              ),
            )
          else
            ...sortedEntries.map((entry) {
              final quantity = entry.value['quantity'];
              final unit = entry.value['unit'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$quantity $unit',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
