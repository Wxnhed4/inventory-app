// lib/screens/batch_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:inventory/custom_drawer.dart';
import 'package:inventory/core/theme/app_colors.dart';
import 'package:inventory/widgets/app_bottom_nav.dart';
import 'package:inventory/widgets/section_card.dart';

class BatchScreen extends StatefulWidget {
  const BatchScreen({super.key});

  @override
  State<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends State<BatchScreen> {
  final CollectionReference _items = FirebaseFirestore.instance.collection(
    'inventory',
  );
  final CollectionReference _batches = FirebaseFirestore.instance.collection(
    'batches',
  );

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _chefCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();

  final Map<String, TextEditingController> _usageCtrls = {};
  final Map<String, String> _itemUnits = {};
  Map<String, int> inventoryMap = {};

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadInventory();
  }

  void _loadInventory() {
    _items.get().then((snapshot) {
      final map = <String, int>{};
      _itemUnits.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name'] as String;
        final qty = data['quantity'] as int;
        final unit = data['unit'] as String? ?? '';
        map[name] = qty;
        _itemUnits[name] = unit;
        if (!_usageCtrls.containsKey(name)) {
          _usageCtrls[name] = TextEditingController();
        }
      }
      setState(() {
        inventoryMap = map;
      });
    });
  }

  void _createBatch() async {
    final batchName = _nameCtrl.text.trim();
    final note = _noteCtrl.text.trim();
    final chef = _chefCtrl.text.trim();
    final date = _dateCtrl.text;
    final List<Map<String, dynamic>> ingredients = [];

    if (batchName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter batch name')));
      return;
    }

    bool hasError = false;

    for (final name in inventoryMap.keys) {
      final usageStr = _usageCtrls[name]!.text.trim();
      final usage = int.tryParse(usageStr) ?? 0;
      final available = inventoryMap[name] ?? 0;

      if (usage <= 0) continue;
      if (usage > available) {
        hasError = true;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Not enough $name in stock')));
        break;
      }

      ingredients.add({
        'name': name,
        'used': usage,
        'unit': _itemUnits[name] ?? '',
      });
    }

    if (hasError) return;

    try {
      await _batches.add({
        'batchName': batchName,
        'note': note,
        'chef': chef,
        'date': date,
        'ingredients': ingredients,
        'timestamp': FieldValue.serverTimestamp(),
      });

      for (final item in ingredients) {
        final name = item['name'] as String;
        final used = item['used'] as int;
        final docs = await _items.where('name', isEqualTo: name).get();
        if (docs.docs.isNotEmpty) {
          await _items.doc(docs.docs.first.id).update({
            'quantity': FieldValue.increment(-used),
          });
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Batch "$batchName" recorded')));

      _nameCtrl.clear();
      _noteCtrl.clear();
      _chefCtrl.clear();
      _dateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      for (var ctrl in _usageCtrls.values) {
        ctrl.clear();
      }

      _loadInventory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Production'),
      ),
      drawer: const CustomDrawer(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionCard(
              child: Padding(
                padding: const EdgeInsets.all(0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeading(
                      title: 'Batch Overview',
                      subtitle:
                          'Create production batches and automatically deduct ingredients from stock.',
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 220,
                          child: MetricTile(
                            label: 'Ingredients Available',
                            value: '${inventoryMap.length}',
                            icon: Icons.inventory_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: MetricTile(
                            label: 'Prepared Date',
                            value: _dateCtrl.text,
                            icon: Icons.calendar_today_outlined,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                      title: 'Create Batch',
                      subtitle:
                          'Enter the batch details and the quantities consumed from inventory.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Product / Batch Name',
                        prefixIcon: Icon(Icons.layers_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _noteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Note (e.g., Batch #1)',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                      ),
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
                          lastDate: DateTime.now(),
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
                        labelText: 'Prepared By',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ingredients Used',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 260,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: inventoryMap.length,
                        itemBuilder: (ctx, index) {
                          final name = inventoryMap.keys.elementAt(index);
                          final available = inventoryMap[name]!;
                          final unit = _itemUnits[name] ?? '';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    '$name ($available $unit)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: _usageCtrls[name]!,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: 'Used',
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _createBatch,
                      child: const Text('Create Batch'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeading(
                    title: 'History',
                    subtitle:
                        'Open the full batch history to review production runs and ingredient usage.',
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const _BatchHistoryScreen(),
                        ),
                      );
                    },
                    child: const Text('See All Batches'),
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
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    _chefCtrl.dispose();
    _dateCtrl.dispose();
    for (var ctrl in _usageCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }
}

class _BatchHistoryScreen extends StatelessWidget {
  const _BatchHistoryScreen();

  @override
  Widget build(BuildContext context) {
    final CollectionReference batches = FirebaseFirestore.instance.collection(
      'batches',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: batches.orderBy('timestamp', descending: true).snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const EmptyStateView(
              icon: Icons.layers_clear_outlined,
              title: 'No batches yet',
              subtitle: 'Created batches will appear here with their details.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = data['batchName'] as String;
              final chef = data['chef'] as String? ?? 'Unknown';
              final date = data['date'] as String? ?? 'Unknown';

              final ingredients = (data['ingredients'] as List)
                  .map((item) {
                    final used = item['used'] as int;
                    final unit = item['unit'] as String;
                    final itemName = item['name'] as String;
                    return '$used $unit $itemName';
                  })
                  .join(', ');

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SectionCard(
                  padding: const EdgeInsets.all(0),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('$date • by $chef'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ingredients,
                              style: const TextStyle(fontSize: 14),
                            ),
                            if ((data['note'] as String? ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Note: ${data['note']}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textSecondary,
                                  ),
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
