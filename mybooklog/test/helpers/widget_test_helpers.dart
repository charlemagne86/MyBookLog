/// Widget testing helpers and utilities.
///
/// Provides common patterns for widget testing, such as pumping test widgets,
/// finding elements, and simulating user interactions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

// ============================================================================
// Test Widget Wrappers
// ============================================================================

/// A minimal Material app wrapper for testing individual widgets.
///
/// Provides a Material context with theme, localization, and Navigator.
class TestAppWrapper extends StatelessWidget {
  /// The widget to test.
  final Widget child;

  /// Providers to inject for the test.
  final List<SingleChildWidget> providers;

  /// Optional theme to use (defaults to light theme).
  final ThemeData? theme;

  /// Optional home widget for the app (rarely needed).
  final Widget? home;

  const TestAppWrapper({
    required this.child,
    this.providers = const [],
    this.theme,
    this.home,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    // Wrap with providers if any
    if (providers.isNotEmpty) {
      content = MultiProvider(providers: providers, child: content);
    }

    // Create the Material app
    if (home != null) {
      return MaterialApp(theme: theme, home: home);
    }

    return MaterialApp(
      theme: theme,
      home: Scaffold(body: content),
      localizationsDelegates: const [],
    );
  }
}

// ============================================================================
// WidgetTester Extensions
// ============================================================================

extension WidgetTesterX on WidgetTester {
  /// Pumps a widget wrapped in [TestAppWrapper] for testing.
  ///
  /// Example:
  /// ```dart
  /// await tester.pumpTestWidget(
  ///   const LoginScreen(),
  ///   providers: [Provider.value(value: mockAuthRepository)],
  /// );
  /// ```
  Future<void> pumpTestWidget(
    Widget widget, {
    List<SingleChildWidget> providers = const [],
    ThemeData? theme,
  }) async {
    await pumpWidget(
      TestAppWrapper(providers: providers, theme: theme, child: widget),
    );
  }

  /// Types text into a TextField, handling the common case of a single input.
  ///
  /// Finds the first TextField and enters the given text, then settles.
  Future<void> typeText(String text) async {
    await enterText(find.byType(TextField), text);
    await pumpAndSettle();
  }

  /// Types text into a specific TextField by label text.
  Future<void> typeTextInField(String label, String text) async {
    final textFieldFinder = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == label,
    );
    await enterText(textFieldFinder, text);
    await pumpAndSettle();
  }

  /// Taps a button by its text label.
  ///
  /// Works with ElevatedButton, TextButton, OutlinedButton.
  Future<void> tapButton(String label) async {
    // Find button by text inside ElevatedButton
    await tap(
      find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.text(label),
      ),
    );
    await pumpAndSettle();
  }

  /// Taps a button by its Icon.
  Future<void> tapIconButton(IconData icon) async {
    await tap(find.byIcon(icon));
    await pumpAndSettle();
  }

  /// Checks if a snackbar with the given message is displayed.
  bool hasSnackbar(String message) {
    return find
        .text(message)
        .evaluate()
        .any((element) => element.widget is Text && element.widget is Text);
  }

  /// Waits for a widget to appear on screen.
  Future<void> waitFor(
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await pumpAndSettle();
    final endTime = DateTime.now().add(timeout);

    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(endTime)) {
        throw Exception('Widget not found after ${timeout.inSeconds}s');
      }
      await pump(const Duration(milliseconds: 100));
    }
  }

  /// Simulates scrolling a scrollable widget to find a specific item.
  Future<void> scrollToFindWidget(Finder itemFinder) async {
    while (itemFinder.evaluate().isEmpty) {
      await dragUntilVisible(
        itemFinder,
        find.byType(ListView),
        const Offset(0, -300),
      );
      await pumpAndSettle();
    }
  }
}

// ============================================================================
// Common Test Scenarios
// ============================================================================

/// Verifies that a screen shows an error dialog.
Future<void> expectErrorDialog(WidgetTester tester, String message) async {
  expect(find.byType(AlertDialog), findsOneWidget);
  expect(find.text(message), findsOneWidget);
}

/// Verifies that a screen shows a loading spinner.
Future<void> expectLoadingState(WidgetTester tester) async {
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
}

/// Verifies that a screen shows an empty state message.
Future<void> expectEmptyState(WidgetTester tester, String message) async {
  expect(find.text(message), findsOneWidget);
}

/// Fills out and submits a login form.
Future<void> fillAndSubmitLoginForm(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  final emailField = find.byType(TextField).first;
  final passwordField = find.byType(TextField).last;

  await tester.enterText(emailField, email);
  await tester.enterText(passwordField, password);
  await tester.pumpAndSettle();

  final loginButton = find.byWidgetPredicate((widget) {
    return widget is ElevatedButton;
  });
  await tester.tap(loginButton);
  await tester.pumpAndSettle();
}

/// Fills out and submits a signup form.
Future<void> fillAndSubmitSignupForm(
  WidgetTester tester, {
  required String firstName,
  required String lastName,
  required String email,
  required String password,
}) async {
  final fields = find.byType(TextFormField);

  // Assuming order: firstName, lastName, email, password, confirmPassword
  if (fields.evaluate().length >= 5) {
    await tester.enterText(fields.at(0), firstName);
    await tester.enterText(fields.at(1), lastName);
    await tester.enterText(fields.at(2), email);
    await tester.enterText(fields.at(3), password);
    await tester.enterText(fields.at(4), password); // confirm password
  }

  await tester.pumpAndSettle();

  final signupButton = find.byType(ElevatedButton);
  await tester.tap(signupButton);
  await tester.pumpAndSettle();
}
