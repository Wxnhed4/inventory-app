import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:inventory/custom_drawer.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final CollectionReference _items = FirebaseFirestore.instance.collection(
    'inventory',
  );

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _unitCtrl = TextEditingController();

  void _addItem() {
    _nameCtrl.clear();
    _qtyCtrl.clear();
    _unitCtrl.clear();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Quantity'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _unitCtrl,
                decoration: const InputDecoration(
                  hintText: 'Unit (e.g., kg, g)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = _nameCtrl.text.trim();
                final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
                print('Saving quantity: $qty (Type: ${qty.runtimeType})');
                final unit = _unitCtrl.text.trim();

                if (name.isNotEmpty) {
                  _items.add({'name': name, 'quantity': qty, 'unit': unit});
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _editItem(DocumentSnapshot item) {
    _nameCtrl.text = item['name'];
    _qtyCtrl.text = item['quantity'].toString();
    _unitCtrl.text = item['unit'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Quantity'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _unitCtrl,
                decoration: const InputDecoration(hintText: 'Unit'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = _nameCtrl.text.trim();
                final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
                final unit = _unitCtrl.text.trim();

                if (name.isNotEmpty) {
                  _items.doc(item.id).update({
                    'name': name,
                    'quantity': qty,
                    'unit': unit,
                  });
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteItem(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete?'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              _items.doc(docId).delete();
              Navigator.pop(ctx);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inventory',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      drawer: CustomDrawer(context: context),
      body: StreamBuilder<QuerySnapshot>(
        stream: _items.orderBy('name').snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No items yet'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, index) {
              final item = docs[index];
              final data = item.data() as Map<String, dynamic>;
              final name = data['name'] as String;
              final qty = data['quantity'] as int;
              final unit = data['unit'] as String? ?? '';

              return ListTile(
                title: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  '$qty $unit',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 20,
                        color: Colors.grey,
                      ),
                      onPressed: () => _editItem(item),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 20,
                        color: Colors.red,
                      ),
                      onPressed: () => _deleteItem(item.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }
}
