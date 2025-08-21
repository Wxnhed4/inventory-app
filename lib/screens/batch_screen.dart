// lib/screens/batch_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:inventory/custom_drawer.dart';

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

    print('Saving batch: $batchName, ingredients: $ingredients');

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New Batch',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      drawer: CustomDrawer(context: context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Batch',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Product / Batch Name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _noteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Note (e.g., Batch #1)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _dateCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Date (YYYY-MM-DD)',
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
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ingredients Used',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: inventoryMap.length,
                        itemBuilder: (ctx, index) {
                          final name = inventoryMap.keys.elementAt(index);
                          final available = inventoryMap[name]!;
                          final unit = _itemUnits[name] ?? '';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text('$name ($available $unit)'),
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
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _createBatch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        'Create Batch',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const _BatchHistoryScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: const Text(
                'See All Batches',
                style: TextStyle(color: Colors.white),
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
        title: const Text(
          'All Batches',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: batches.orderBy('timestamp', descending: true).snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No batches yet'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = data['batchName'] as String;
              final chef = data['chef'] as String;
              final date = data['date'] as String;

              final ingredients = (data['ingredients'] as List)
                  .map((item) {
                    final used = item['used'] as int;
                    final unit = item['unit'] as String;
                    final itemName = item['name'] as String;
                    return '$used $unit $itemName';
                  })
                  .join(', ');

              return ExpansionTile(
                title: Text(name),
                subtitle: Text('$date • by $chef'),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ingredients,
                          style: const TextStyle(fontSize: 14),
                        ),
                        if ((data['note'] as String? ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Note: ${data['note']}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
