import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:inventory/custom_drawer.dart';
import 'package:inventory/core/theme/app_colors.dart';
import 'package:inventory/widgets/section_card.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final CollectionReference _items = FirebaseFirestore.instance.collection(
    'inventory',
  );

  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _unitCtrl = TextEditingController();

  void _addItem() {
    _nameCtrl.clear();
    _qtyCtrl.clear();
    _unitCtrl.clear();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildItemSheet(
        ctx,
        title: 'Add Inventory Item',
        buttonLabel: 'Save Item',
        onSubmit: () {
          final name = _nameCtrl.text.trim();
          final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
          final unit = _unitCtrl.text.trim();

          if (name.isNotEmpty) {
            _items.add({'name': name, 'quantity': qty, 'unit': unit});
          }
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _editItem(DocumentSnapshot item) {
    _nameCtrl.text = item['name'];
    _qtyCtrl.text = item['quantity'].toString();
    _unitCtrl.text = item['unit'] ?? '';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildItemSheet(
        ctx,
        title: 'Edit Inventory Item',
        buttonLabel: 'Update Item',
        onSubmit: () {
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
      ),
    );
  }

  void _deleteItem(String docId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: const Text('This will remove the item from inventory.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _items.doc(docId).delete();
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemSheet(
    BuildContext context, {
    required String title,
    required String buttonLabel,
    required VoidCallback onSubmit,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SectionCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Item name',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                prefixIcon: Icon(Icons.straighten_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _unitCtrl,
              decoration: const InputDecoration(
                labelText: 'Unit',
                hintText: 'kg, g, pcs',
                prefixIcon: Icon(Icons.category_outlined),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSubmit,
                    child: Text(buttonLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
      ),
      drawer: const CustomDrawer(),
      body: StreamBuilder<QuerySnapshot>(
        stream: _items.orderBy('name').snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final query = _searchCtrl.text.trim().toLowerCase();
          final filteredDocs = docs.where((item) {
            final data = item.data() as Map<String, dynamic>;
            final name = (data['name'] as String? ?? '').toLowerCase();
            final unit = (data['unit'] as String? ?? '').toLowerCase();
            return name.contains(query) || unit.contains(query);
          }).toList();
          final totalQuantity = docs.fold<int>(0, (runningTotal, item) {
            final data = item.data() as Map<String, dynamic>;
            return runningTotal + ((data['quantity'] as int?) ?? 0);
          });
          final lowStockCount = docs.where((item) {
            final data = item.data() as Map<String, dynamic>;
            return ((data['quantity'] as int?) ?? 0) <= 5;
          }).length;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeading(
                      title: 'Stock Control',
                      subtitle:
                          'Manage ingredient quantities and keep an eye on low-stock items.',
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 220,
                          child: MetricTile(
                            label: 'Items',
                            value: '${docs.length}',
                            icon: Icons.inventory_2_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: MetricTile(
                            label: 'Total Quantity',
                            value: '$totalQuantity',
                            icon: Icons.stacked_bar_chart_rounded,
                            color: AppColors.accent,
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: MetricTile(
                            label: 'Low Stock',
                            value: '$lowStockCount',
                            icon: Icons.warning_amber_rounded,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Search inventory',
                        hintText: 'Search by name or unit',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _FilterBadge(
                          label: 'All Items',
                          value: '${docs.length}',
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        _FilterBadge(
                          label: 'Low Stock',
                          value: '$lowStockCount',
                          color: AppColors.error,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (docs.isEmpty)
                const SizedBox(
                  height: 280,
                  child: EmptyStateView(
                    icon: Icons.inventory_2_outlined,
                    title: 'No inventory yet',
                    subtitle:
                        'Add your first ingredient to start tracking stock levels.',
                  ),
                )
              else if (filteredDocs.isEmpty)
                const SizedBox(
                  height: 220,
                  child: EmptyStateView(
                    icon: Icons.search_off_rounded,
                    title: 'No matching items',
                    subtitle:
                        'Try a different search term or clear the search field.',
                  ),
                )
              else
                ...filteredDocs.map((item) {
                  final data = item.data() as Map<String, dynamic>;
                  final name = data['name'] as String? ?? '';
                  final qty = data['quantity'] as int? ?? 0;
                  final unit = data['unit'] as String? ?? '';
                  final isLowStock = qty <= 5;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SectionCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: (isLowStock
                                    ? AppColors.error
                                    : AppColors.primary)
                                .withValues(alpha: 0.10),
                            foregroundColor: isLowStock
                                ? AppColors.error
                                : AppColors.primary,
                            child: const Icon(Icons.kitchen_outlined),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$qty $unit available',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: (isLowStock
                                      ? AppColors.error
                                      : AppColors.success)
                                  .withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              isLowStock ? 'Low stock' : 'Healthy',
                              style: TextStyle(
                                color: isLowStock
                                    ? AppColors.error
                                    : AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editItem(item);
                              } else {
                                _deleteItem(item.id);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
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
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }
}

class _FilterBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _FilterBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
