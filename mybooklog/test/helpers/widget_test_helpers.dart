import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Extension methods providing common widget test utilities.
extension WidgetTesterHelpers on WidgetTester {
  /// Types text into a TextField identified by its label text.
  Future<void> typeTextInField(String label, String text) async {
    final textFieldFinder = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == label,
    );
    await enterText(textFieldFinder, text);
    await pumpAndSettle();
  }

  /// Taps a button containing the given text label.
  Future<void> tapButton(String label) async {
    await tap(
      find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.text(label),
      ),
    );
    await pumpAndSettle();
  }

  /// Taps an icon button with the given icon.
  Future<void> tapIconButton(IconData icon) async {
    await tap(find.byIcon(icon));
    await pumpAndSettle();
  }

  /// Checks if a snackbar message is currently displayed.
  bool hasSnackbar(String message) {
    return find.text(message).evaluate().isNotEmpty;
  }

  /// Waits for a widget matching the finder to appear on screen.
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

  /// Scrolls within a ListView to find and display a widget.
  Future<void> scrollToFindWidget(Finder itemFinder) async {
    while (itemFinder.evaluate().isEmpty) {
      await scrollUntilVisible(
        itemFinder,
        300,
        scrollable: find.byType(ListView).first,
      );
      await pumpAndSettle();
    }
  }

  /// Sets the display size for responsive UI testing.
  Future<void> setDisplaySize(Size size) async {
    addTearDown(binding.window.clearPhysicalSizeTestValue);
    binding.window.physicalSizeTestValue = size;
  }
}
