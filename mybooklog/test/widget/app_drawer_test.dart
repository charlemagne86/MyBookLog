/// Widget tests for [AppDrawer].
///
/// BUSINESS LOGIC:
/// This is the side menu's whole contract with the rest of the app: show
/// the signed-in user's name, and report exactly which item was tapped so
/// the parent screen can navigate or sign out. Theme switching is out of
/// scope for now, so tapping "Theme" must do nothing beyond closing the
/// drawer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybooklog/src/features/bookshelf/widgets/app_drawer.dart';

void main() {
  group('AppDrawer', () {
    Future<void> pumpDrawer(
      WidgetTester tester, {
      required VoidCallback onProfileTap,
      required VoidCallback onLogoutTap,
      String displayName = 'Jane Doe',
    }) async {
      final scaffoldKey = GlobalKey<ScaffoldState>();
      await tester.pumpWidget(
        MaterialApp(
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
      );
      scaffoldKey.currentState!.openDrawer();
      await tester.pumpAndSettle();
    }

    testWidgets('shows the display name and every menu item', (tester) async {
      await pumpDrawer(tester, onProfileTap: () {}, onLogoutTap: () {});

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
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

    testWidgets('tapping Theme closes the drawer without navigating', (
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
      expect(find.text('Theme'), findsNothing); // drawer is closed
    });
  });
}
