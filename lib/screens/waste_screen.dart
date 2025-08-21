// lib/screens/waste_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:inventory/custom_drawer.dart';

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
    print('Saving waste: $_selectedItemId, $_selectedItemName, $amountStr');
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
      // 1. Record waste
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

      // 2. Update inventory
      await _items.doc(_selectedItemId!).update({
        'quantity': currentQty - amount,
      });

      // 3. Refresh inventory
      _loadInventory();

      
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
        title: const Text(
          'Record Waste',
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
                      'Add Waste',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: _recordWaste,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        'Record Waste',
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
                    builder: (context) => const _WasteHistoryScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: const Text(
                'See All Wastes',
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
        title: const Text(
          'All Waste Records',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: waste.orderBy('timestamp', descending: true).snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No waste records yet'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = data['itemName'] ?? 'Unknown';
              final qty = data['wastedQty'] as int? ?? 0;
              final unit = data['unit'] ?? '';
              final reason = data['reason'] ?? 'No reason';
              final chef = data['chef'] ?? 'Unknown';
              final date = data['date'] ?? 'Unknown';

              return ListTile(
                title: Text('$name - $qty $unit'),
                subtitle: Text('$reason • $date • by $chef'),
              );
            },
          );
        },
      ),
    );
  }
}
