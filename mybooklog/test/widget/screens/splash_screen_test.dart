import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybooklog/src/features/auth/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/test_app_builder.dart';
import '../../unit/mocks/mock_repositories.dart';

void main() {
  late MockBookshelfRepository mockBookshelfRepository;
  late MockAuthRepository mockAuthRepository;
  late StreamController<AuthState> authStateController;

  setUp(() {
    mockBookshelfRepository = MockBookshelfRepository();
    mockAuthRepository = MockAuthRepository();
    authStateController = StreamController<AuthState>.broadcast();
  });

  tearDown(() {
    authStateController.close();
  });

  group('SplashScreen', () {
    testWidgets('displays splash screen on startup', (
      WidgetTester tester,
    ) async {
      TestSetupHelpers.setupLoggedOutUser(
        mockAuthRepository,
        authStateController,
      );

      await tester.pumpWidget(
        TestAppBuilder(
          bookshelfRepository: mockBookshelfRepository,
          authRepository: mockAuthRepository,
          authStateController: authStateController,
        ).build(),
      );

      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);

      // Cleanup: wait for timers to complete
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    });

    testWidgets('shows loading spinner during splash', (
      WidgetTester tester,
    ) async {
      TestSetupHelpers.setupLoggedOutUser(
        mockAuthRepository,
        authStateController,
      );

      await tester.pumpWidget(
        TestAppBuilder(
          bookshelfRepository: mockBookshelfRepository,
          authRepository: mockAuthRepository,
          authStateController: authStateController,
        ).build(),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Cleanup: wait for timers to complete
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    });

    testWidgets('displays text on splash', (WidgetTester tester) async {
      TestSetupHelpers.setupLoggedOutUser(
        mockAuthRepository,
        authStateController,
      );

      await tester.pumpWidget(
        TestAppBuilder(
          bookshelfRepository: mockBookshelfRepository,
          authRepository: mockAuthRepository,
          authStateController: authStateController,
        ).build(),
      );

      await tester.pump();

      expect(find.byType(Text), findsWidgets);
      expect(find.byType(SplashScreen), findsOneWidget);

      // Cleanup: wait for timers to complete
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    });

    testWidgets(
      'shows the app icon above the name, so OS launch icon and Flutter '
      'splash read as one continuous screen',
      (WidgetTester tester) async {
        TestSetupHelpers.setupLoggedOutUser(
          mockAuthRepository,
          authStateController,
        );

        await tester.pumpWidget(
          TestAppBuilder(
            bookshelfRepository: mockBookshelfRepository,
            authRepository: mockAuthRepository,
            authStateController: authStateController,
          ).build(),
        );

        await tester.pump();

        final image = tester.widget<Image>(find.byType(Image));
        expect(image.image, isA<AssetImage>());
        expect(
          (image.image as AssetImage).assetName,
          'assets/icon/app_icon_512.png',
        );
        // Icon must be above the title, not below or beside it.
        final iconTop = tester.getTopLeft(find.byType(Image)).dy;
        final titleTop = tester.getTopLeft(find.text('My Book Log')).dy;
        expect(iconTop, lessThan(titleTop));

        // Cleanup: wait for timers to complete
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
      },
    );

    testWidgets(
      'stays visible long enough to actually read the name and tagline',
      (WidgetTester tester) async {
        // BUSINESS LOGIC / REGRESSION: the splash previously navigated away
        // after only 1.2s minimum visibility, which registered as a quick
        // flash rather than something readable. Thresholds below have
        // margin on both sides of the real measured transition (the 2.5s
        // delay plus ~400-500ms for Flutter's page-transition animation
        // to finish unmounting the old route, landing around t=2.9-3.0s)
        // so this fails clearly if the minimum is ever shrunk back down.
        TestSetupHelpers.setupLoggedOutUser(
          mockAuthRepository,
          authStateController,
        );

        await tester.pumpWidget(
          TestAppBuilder(
            bookshelfRepository: mockBookshelfRepository,
            authRepository: mockAuthRepository,
            authStateController: authStateController,
          ).build(),
        );
        await tester.pump();

        // Advance in small steps rather than one big jump: the page
        // transition that unmounts SplashScreen is ticker-driven, and a
        // single large pump() doesn't simulate the intermediate frames a
        // real animation needs — it can under-report how long the old
        // route actually stays mounted.
        const step = Duration(milliseconds: 100);
        var elapsedMs = 0;
        while (elapsedMs < 2000) {
          await tester.pump(step);
          elapsedMs += 100;
        }
        // Comfortably still visible well past where a 1.2s minimum would
        // have already finished transitioning away.
        expect(find.byType(SplashScreen), findsOneWidget);

        while (elapsedMs < 3500) {
          await tester.pump(step);
          elapsedMs += 100;
        }
        // Gone well after the 2.5s minimum plus transition time.
        expect(find.byType(SplashScreen), findsNothing);
      },
    );

    testWidgets('navigates away from splash eventually', (
      WidgetTester tester,
    ) async {
      TestSetupHelpers.setupLoggedOutUser(
        mockAuthRepository,
        authStateController,
      );

      await tester.pumpWidget(
        TestAppBuilder(
          bookshelfRepository: mockBookshelfRepository,
          authRepository: mockAuthRepository,
          authStateController: authStateController,
        ).build(),
      );

      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(SplashScreen), findsNothing);
    });

    testWidgets('responds to auth state changes', (WidgetTester tester) async {
      TestSetupHelpers.setupLoggedOutUser(
        mockAuthRepository,
        authStateController,
      );

      await tester.pumpWidget(
        TestAppBuilder(
          bookshelfRepository: mockBookshelfRepository,
          authRepository: mockAuthRepository,
          authStateController: authStateController,
        ).build(),
      );

      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);

      final testBooks = TestBookFactory.createTestBooks(1);
      TestSetupHelpers.setupLoggedInUserWithBooks(
        mockAuthRepository,
        mockBookshelfRepository,
        testBooks,
        authStateController,
      );

      await tester.pumpAndSettle();
      expect(find.byType(SplashScreen), findsNothing);
    });

    testWidgets('splash screen mounts without error', (
      WidgetTester tester,
    ) async {
      TestSetupHelpers.setupLoggedOutUser(
        mockAuthRepository,
        authStateController,
      );

      await tester.pumpWidget(
        TestAppBuilder(
          bookshelfRepository: mockBookshelfRepository,
          authRepository: mockAuthRepository,
          authStateController: authStateController,
        ).build(),
      );

      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Cleanup: wait for timers to complete
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    });
  });
}
