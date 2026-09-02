import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// The bookshelf screen's side menu: the user's name up top, then Profile
/// and Theme. Purely presentational — the parent screen owns navigation and
/// auth, this just reports which item was tapped.
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.displayName,
    required this.onProfileTap,
    required this.onLogoutTap,
  });

  final String displayName;
  final VoidCallback onProfileTap;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: AppColors.background),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Row(
                  children: [
                    const Icon(Icons.account_circle, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.of(context).pop();
                onProfileTap();
              },
            ),
            ListTile(
              leading: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary,
                ),
              ),
              title: const Text('Theme'),
              // Switching themes is out of scope for now; this just closes
              // the drawer rather than being a dead tap target.
              trailing: Text(
                'Soon',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
              ),
              onTap: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.of(context).pop();
                onLogoutTap();
              },
            ),
          ],
        ),
      ),
    );
  }
}
