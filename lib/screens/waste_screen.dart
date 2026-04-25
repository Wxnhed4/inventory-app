// lib/screens/waste_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:inventory/custom_drawer.dart';
import 'package:inventory/core/theme/app_colors.dart';
import 'package:inventory/widgets/section_card.dart';

class WasteScreen extends StatefulWidget {
  const WasteScreen({super.key});

  @override
  State<WasteScreen> createState() => _WasteScreenState();
}

class _WasteScreenState extends State<WasteScreen> {
  final CollectionReference _items = FirebaseFirestore.instance.collection(
    'inventory',
  );
  final CollectionReference _waste = FirebaseFirestore.instance.collection(
    'waste',
  );

  String? _selectedItemName;
  String? _selectedItemId;
  final TextEditingController _amountCtrl = TextEditingController();
  String? _reason = 'Spoiled';
  final TextEditingController _dateCtrl = TextEditingController();
  final TextEditingController _chefCtrl = TextEditingController();

  Map<String, Map<String, dynamic>> inventoryMap = {};

  final List<String> reasons = [
    'Spoiled',
    'Spill',
    'Over-preparation',
    'Pest damage',
    'Expired',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadInventory();
  }

  void _loadInventory() {
    _items.get().then((snapshot) {
      final map = <String, Map<String, dynamic>>{};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name'] as String;
        map[name] = {
          'id': doc.id,
          'quantity': data['quantity'] as int,
          'unit': data['unit'] as String? ?? '',
        };
      }
      setState(() {
        inventoryMap = map;
      });
    });
  }

  void _recordWaste() async {
    final amountStr = _amountCtrl.text.trim();
    if (_selectedItemId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a product')));
      return;
    }

    final amount = int.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_reason == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a reason')));
      return;
    }

    if (_chefCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter chef name')));
      return;
    }

    final unit = inventoryMap[_selectedItemName]?['unit'] ?? '';
    final currentQty = inventoryMap[_selectedItemName]?['quantity'] ?? 0;

    if (amount > currentQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot waste more than available!')),
      );
      return;
    }

    try {
      await _waste.add({
        'itemId': _selectedItemId,
        'itemName': _selectedItemName,
        'wastedQty': amount,
        'unit': unit,
        'reason': _reason,
        'chef': _chefCtrl.text.trim(),
        'date': _dateCtrl.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _items.doc(_selectedItemId!).update({
        'quantity': currentQty - amount,
      });

      _loadInventory();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$amount $unit of $_selectedItemName wasted')),
      );

      setState(() {
        _selectedItemName = null;
        _selectedItemId = null;
        _amountCtrl.clear();
        _reason = 'Spoiled';
        _chefCtrl.text = "";
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waste Tracking'),
      ),
      drawer: const CustomDrawer(),
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
                    title: 'Waste Control',
                    subtitle:
                        'Log damaged or spoiled ingredients and keep the stock accurate.',
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 220,
                        child: MetricTile(
                          label: 'Tracked Items',
                          value: '${inventoryMap.length}',
                          icon: Icons.inventory_2_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: MetricTile(
                          label: 'Waste Reasons',
                          value: '${reasons.length}',
                          icon: Icons.rule_folder_outlined,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Padding(
                padding: const EdgeInsets.all(0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeading(
                      title: 'Record New Waste',
                      subtitle:
                          'Select an ingredient, quantity lost, and the reason for the waste.',
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedItemName,
                      hint: const Text('Select Product'),
                      items: inventoryMap.keys.map((name) {
                        final unit = inventoryMap[name]?['unit'] ?? '';
                        final qty = inventoryMap[name]?['quantity'] ?? 0;
                        return DropdownMenuItem(
                          value: name,
                          child: Text('$name ($qty $unit)'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedItemName = value;
                          _selectedItemId = inventoryMap[value]?['id'];
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Product'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount Wasted',
                        prefixIcon: Icon(Icons.remove_circle_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _reason,
                      items: reasons
                          .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _reason = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Reason'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _dateCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Date (YYYY-MM-DD)',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (date != null) {
                          _dateCtrl.text = DateFormat(
                            'yyyy-MM-dd',
                          ).format(date);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _chefCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Reported By',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _recordWaste,
                      child: const Text('Record Waste'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                children: [
                  const SectionHeading(
                    title: 'History',
                    subtitle:
                        'Review previous waste records for auditing and reporting.',
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const _WasteHistoryScreen(),
                        ),
                      );
                    },
                    child: const Text('See All Waste Records'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();

    _chefCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }
}

// WASTE HISTORY SCREEN
class _WasteHistoryScreen extends StatelessWidget {
  const _WasteHistoryScreen();

  @override
  Widget build(BuildContext context) {
    final CollectionReference waste = FirebaseFirestore.instance.collection(
      'waste',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Waste History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: waste.orderBy('timestamp', descending: true).snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const EmptyStateView(
              icon: Icons.delete_outline_rounded,
              title: 'No waste records yet',
              subtitle: 'Your logged waste entries will appear here.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = data['itemName'] ?? 'Unknown';
              final qty = data['wastedQty'] as int? ?? 0;
              final unit = data['unit'] ?? '';
              final reason = data['reason'] ?? 'No reason';
              final chef = data['chef'] ?? 'Unknown';
              final date = data['date'] ?? 'Unknown';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SectionCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            AppColors.accent.withValues(alpha: 0.12),
                        foregroundColor: AppColors.accent,
                        child: const Icon(Icons.delete_sweep_rounded),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$name - $qty $unit',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$reason • $date • by $chef',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
