import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_provider.dart';

/// The bookshelf screen's side menu: the user's name up top, then Profile
/// and Theme. Navigation/auth (Profile, Logout) are reported to the parent
/// screen via callbacks; the theme picker is self-contained here since
/// [ThemeProvider] is already app-wide state, not something the parent
/// screen otherwise touches.
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

  Future<void> _showThemePicker(BuildContext context) async {
    final themeProvider = context.read<ThemeProvider>();
    final current = themeProvider.themeColor;
    final colorScheme = Theme.of(context).colorScheme;

    final selected = await showDialog<AppThemeColor>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeColor.values.map((option) {
            return ListTile(
              leading: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: option.seedColor,
                ),
              ),
              title: Text(option.label),
              trailing: option == current
                  ? Icon(Icons.check, color: colorScheme.primary)
                  : null,
              onTap: () => Navigator.of(dialogContext).pop(option),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected != null) {
      themeProvider.setThemeColor(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Rebuilds the subtitle label whenever the theme changes, since the
    // drawer deliberately stays open after a pick so the color dot's live
    // update is visible feedback.
    final themeColor = context.watch<ThemeProvider>().themeColor;
    return Drawer(
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Row(
                children: [
                  const Icon(Icons.account_circle, size: 36),
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
            const Divider(height: 1),
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
              subtitle: Text(themeColor.label),
              // Deliberately doesn't close the drawer: picking a color shows
              // its effect immediately in the still-open drawer (the dot
              // above updates live), which is more convincing than a color
              // swatch alone.
              onTap: () => _showThemePicker(context),
            ),
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
