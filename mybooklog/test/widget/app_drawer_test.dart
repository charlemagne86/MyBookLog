/// Widget tests for [AppDrawer].
///
/// BUSINESS LOGIC:
/// This is the side menu's whole contract with the rest of the app: show
/// the signed-in user's name, report exactly which item was tapped so the
/// parent screen can navigate or sign out, and let the user pick an accent
/// color inline — an accordion row that expands right in the drawer (not a
/// popup), auto-collapsing once a color is picked.
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
      expect(find.text('Sage'), findsOneWidget); // current theme, collapsed
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

    group('Theme accordion', () {
      testWidgets(
        'tapping Theme expands color options inline, without leaving the '
        'drawer',
        (tester) async {
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
          // Indigo/Terracotta only ever appear as expanded option rows,
          // never in the collapsed subtitle (that shows the *current*
          // color) — seeing them proves the accordion expanded in place.
          expect(find.text('Indigo'), findsOneWidget);
          expect(find.text('Terracotta'), findsOneWidget);
          // Still the same open drawer, not a separate dialog/route.
          expect(find.text('Profile'), findsOneWidget);
          expect(find.text('Logout'), findsOneWidget);
        },
      );

      testWidgets('shows a checkmark next to the current selection only', (
        tester,
      ) async {
        await pumpDrawer(tester, onProfileTap: () {}, onLogoutTap: () {});

        await tester.tap(find.text('Theme'));
        await tester.pumpAndSettle();

        // "Sage" now appears twice: the collapsed-row subtitle plus the
        // expanded option row. The other options appear once each (row only).
        expect(find.text('Sage'), findsNWidgets(2));
        expect(find.text('Indigo'), findsOneWidget);
        expect(find.text('Terracotta'), findsOneWidget);
        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('selecting a color applies it and collapses the accordion', (
        tester,
      ) async {
        final themeProvider = await pumpDrawer(
          tester,
          onProfileTap: () {},
          onLogoutTap: () {},
        );

        await tester.tap(find.text('Theme'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Indigo'));
        await tester.pumpAndSettle();

        expect(themeProvider.themeColor, AppThemeColor.indigo);
        // Collapsed again: "Sage" (no longer selected, and no longer
        // expanded) isn't shown anywhere now.
        expect(find.text('Sage'), findsNothing);
        expect(find.text('Indigo'), findsOneWidget); // just the subtitle
        expect(find.text('Terracotta'), findsNothing); // collapsed away too
      });

      testWidgets('tapping Theme again collapses without changing anything', (
        tester,
      ) async {
        final themeProvider = await pumpDrawer(
          tester,
          onProfileTap: () {},
          onLogoutTap: () {},
        );

        await tester.tap(find.text('Theme'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Theme'));
        await tester.pumpAndSettle();

        expect(themeProvider.themeColor, AppThemeColor.sage);
        expect(find.text('Indigo'), findsNothing); // only shown while expanded
      });
    });
  });
}
