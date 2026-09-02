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

  @override
  Widget build(BuildContext context) {
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
            const _ThemeAccordion(),
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

/// The "Theme" row: an inline accordion (not a popup) that expands, right in
/// place in the drawer, to list every accent color with a checkmark on the
/// current one. Picking one applies it immediately and collapses back down.
class _ThemeAccordion extends StatefulWidget {
  const _ThemeAccordion();

  @override
  State<_ThemeAccordion> createState() => _ThemeAccordionState();
}

class _ThemeAccordionState extends State<_ThemeAccordion> {
  final _controller = ExpansibleController();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final current = themeProvider.themeColor;
    final colorScheme = Theme.of(context).colorScheme;

    return ExpansionTile(
      controller: _controller,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: EdgeInsets.zero,
      leading: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.primary,
        ),
      ),
      title: const Text('Theme'),
      subtitle: Text(current.label),
      children: AppThemeColor.values.map((option) {
        final isSelected = option == current;
        return ListTile(
          contentPadding: const EdgeInsets.only(left: 44, right: 16),
          leading: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: option.seedColor,
            ),
          ),
          title: Text(option.label),
          trailing: isSelected
              ? Icon(Icons.check, color: colorScheme.primary)
              : null,
          onTap: () {
            themeProvider.setThemeColor(option);
            _controller.collapse();
          },
        );
      }).toList(),
    );
  }
}
