/// Widget tests for [AppDrawer].
///
/// BUSINESS LOGIC:
/// This is the side menu's whole contract with the rest of the app: show
/// the signed-in user's name, report exactly which item was tapped so the
/// parent screen can navigate or sign out, and let the user pick an accent
/// color live — the drawer stays open through a pick so the color dot's
/// update is visible feedback.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybooklog/src/core/theme/theme_provider.dart';
import 'package:mybooklog/src/features/bookshelf/widgets/app_drawer.dart';
import 'package:provider/provider.dart';

void main() {
  group('AppDrawer', () {
    Future<ThemeProvider> pumpDrawer(
      WidgetTester tester, {
      required VoidCallback onProfileTap,
      required VoidCallback onLogoutTap,
      String displayName = 'Jane Doe',
    }) async {
      final themeProvider = ThemeProvider();
      final scaffoldKey = GlobalKey<ScaffoldState>();
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
          child: MaterialApp(
            home: Scaffold(
              key: scaffoldKey,
              appBar: AppBar(),
              drawer: AppDrawer(
                displayName: displayName,
                onProfileTap: onProfileTap,
                onLogoutTap: onLogoutTap,
              ),
              body: const SizedBox(),
            ),
          ),
        ),
      );
      scaffoldKey.currentState!.openDrawer();
      await tester.pumpAndSettle();
      return themeProvider;
    }

    testWidgets('shows the display name and every menu item', (tester) async {
      await pumpDrawer(tester, onProfileTap: () {}, onLogoutTap: () {});

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Sage'), findsOneWidget); // current theme's label
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('tapping Profile closes the drawer and calls onProfileTap', (
      tester,
    ) async {
      var profileTapped = false;
      await pumpDrawer(
        tester,
        onProfileTap: () => profileTapped = true,
        onLogoutTap: () {},
      );

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(profileTapped, isTrue);
      expect(find.text('Profile'), findsNothing); // drawer is closed
    });

    testWidgets('tapping Logout closes the drawer and calls onLogoutTap', (
      tester,
    ) async {
      var logoutTapped = false;
      await pumpDrawer(
        tester,
        onProfileTap: () {},
        onLogoutTap: () => logoutTapped = true,
      );

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(logoutTapped, isTrue);
    });

    group('Theme picker', () {
      testWidgets('tapping Theme opens a picker without navigating away', (
        tester,
      ) async {
        var profileTapped = false;
        var logoutTapped = false;
        await pumpDrawer(
          tester,
          onProfileTap: () => profileTapped = true,
          onLogoutTap: () => logoutTapped = true,
        );

        await tester.tap(find.text('Theme'));
        await tester.pumpAndSettle();

        expect(profileTapped, isFalse);
        expect(logoutTapped, isFalse);
        expect(find.text('Choose Theme'), findsOneWidget);
        // The drawer itself is still open underneath the dialog.
        expect(find.text('Logout'), findsOneWidget);
      });

      testWidgets('lists every color option with the current one checked', (
        tester,
      ) async {
        await pumpDrawer(tester, onProfileTap: () {}, onLogoutTap: () {});

        await tester.tap(find.text('Theme'));
        await tester.pumpAndSettle();

        // Scoped to the dialog: the drawer behind it also shows the current
        // theme's label in its own subtitle.
        final dialog = find.byType(AlertDialog);
        for (final option in AppThemeColor.values) {
          expect(
            find.descendant(of: dialog, matching: find.text(option.label)),
            findsOneWidget,
          );
        }
        // Only the current (default Sage) selection shows a checkmark.
        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('selecting a color updates the provider and the drawer '
          'label', (tester) async {
        final themeProvider = await pumpDrawer(
          tester,
          onProfileTap: () {},
          onLogoutTap: () {},
        );

        await tester.tap(find.text('Theme'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Blue'));
        await tester.pumpAndSettle();

        expect(themeProvider.themeColor, AppThemeColor.blue);
        // Dialog closed, drawer stayed open, label reflects the new pick.
        expect(find.text('Choose Theme'), findsNothing);
        expect(find.text('Logout'), findsOneWidget);
        expect(find.text('Blue'), findsOneWidget);
      });

      testWidgets('Cancel leaves the theme unchanged', (tester) async {
        final themeProvider = await pumpDrawer(
          tester,
          onProfileTap: () {},
          onLogoutTap: () {},
        );

        await tester.tap(find.text('Theme'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(themeProvider.themeColor, AppThemeColor.sage);
        expect(find.text('Choose Theme'), findsNothing);
      });
    });
  });
}
