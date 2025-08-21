// lib/widgets/custom_drawer.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomDrawer extends StatelessWidget {
  final BuildContext context;

  const CustomDrawer({super.key, required this.context});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header Section
          DrawerHeader(
            child: Text(
              'Inventory System',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),

          // Navigation Options
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Inventory'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.pushNamed(context, '/inventory');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Waste'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.pushNamed(context, '/waste');
            },
          ),
          ListTile(
            leading: const Icon(Icons.batch_prediction),
            title: const Text('Batch'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.pushNamed(context, '/batch');
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Reports'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.pushNamed(context, '/reports');
            },
          ),

          // Spacer and Log Out Button
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log Out'),
            onTap: () async {
              Navigator.pop(context); // Close the drawer
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }
}
