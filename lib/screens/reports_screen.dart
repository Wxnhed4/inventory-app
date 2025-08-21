// lib/screens/reports_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
    final query = _waste;
    if (_startDate != null && _endDate != null) {
      query
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
    Map<String, Map<String, dynamic>> wasteByIngredient = {};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final ingredient = data['itemName'] as String;
      final wastedQty = data['wastedQty'] as int;
      final unit = data['unit'] as String? ?? '';

      if (!wasteByIngredient.containsKey(ingredient)) {
        wasteByIngredient[ingredient] = {'quantity': 0, 'unit': unit};
      }
      wasteByIngredient[ingredient]!['quantity'] += wastedQty;
    }
    return wasteByIngredient;
  }

  Future<Map<String, Map<String, dynamic>>> _getBatchUsage() async {
    final query = _batches;
    if (_startDate != null && _endDate != null) {
      query
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
    Map<String, Map<String, dynamic>> usageByIngredient = {};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final ingredients = data['ingredients'] as List<dynamic>;
      for (var item in ingredients) {
        final name = item['name'] as String;
        final used = item['used'] as int;
        final unit = item['unit'] as String? ?? '';

        if (!usageByIngredient.containsKey(name)) {
          usageByIngredient[name] = {'quantity': 0, 'unit': unit};
        }
        usageByIngredient[name]!['quantity'] += used;
      }
    }
    return usageByIngredient;
  }

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Range Picker
            ElevatedButton(
              onPressed: _selectDateRange,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: Text(
                _startDate != null && _endDate != null
                    ? 'Filter: ${DateFormat('yyyy-MM-dd').format(_startDate!)} to ${DateFormat('yyyy-MM-dd').format(_endDate!)}'
                    : 'Select Date Range',
                style: const TextStyle(color: Colors.white),
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
                return _buildReportSection(
                  'Waste by Ingredient',
                  wasteByIngredient,
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
                return _buildReportSection('Batch Usage', batchUsage);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSection(
    String title,
    Map<String, Map<String, dynamic>> data,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (data.isEmpty)
          const Text('No data available.')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final key = data.keys.elementAt(index);
              final quantity = data[key]!['quantity'];
              final unit = data[key]!['unit'];
              return ListTile(
                title: Text(key),
                subtitle: Text('$quantity $unit'),
              );
            },
          ),
      ],
    );
  }
}
