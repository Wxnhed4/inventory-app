import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'services/auth_service.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Icon(
                    Icons.restaurant_menu_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'KitchenStock Pro',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kitchen operations workspace',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          _DrawerTile.icon(
            icon: Icons.dashboard_outlined,
            title: 'Dashboard',
            routeName: '/dashboard',
          ),
          _DrawerTile(
            leading: const Icon(Icons.inventory),
            title: 'Inventory',
            routeName: '/inventory',
          ),
          _DrawerTile(
            leading: const Icon(Icons.delete_outline),
            title: 'Waste',
            routeName: '/waste',
          ),
          _DrawerTile(
            leading: const Icon(Icons.batch_prediction),
            title: 'Batch',
            routeName: '/batch',
          ),
          _DrawerTile(
            leading: const Icon(Icons.bar_chart),
            title: 'Reports',
            routeName: '/reports',
          ),
          _DrawerTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: 'Profile',
            routeName: '/profile',
          ),
          _DrawerTile(
            leading: const Icon(Icons.settings_outlined),
            title: 'Settings',
            routeName: '/settings',
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log Out'),
            onTap: () async {
              Navigator.pop(context);
              await AuthService().signOut();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String routeName;

  const _DrawerTile({
    required this.leading,
    required this.title,
    required this.routeName,
  });

  _DrawerTile.icon({
    required IconData icon,
    required this.title,
    required this.routeName,
  }) : leading = Icon(icon);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, routeName);
      },
    );
  }
}
