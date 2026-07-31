import 'package:flutter_test/flutter_test.dart';
import 'package:mybooklog/src/core/config/app_config.dart';

// BUSINESS LOGIC:
// AppConfig provides compile-time configuration for external services.
// When Google Books API key is not provided (for privacy or CI testing),
// the app should gracefully disable book search instead of crashing.
//
// TECHNICAL:
// Constants come from --dart-define at build time.
// hasGoogleBooksApiKey is a convenience getter to check if feature is enabled.

void main() {
  group('AppConfig', () {
    // BUSINESS LOGIC: API key is provided (normal build)
    test('hasGoogleBooksApiKey returns true when key is non-empty', () {
      // In test environment, key may or may not be provided
      // This test documents the contract: key.isNotEmpty => hasGoogleBooksApiKey
      final hasKey = AppConfig.hasGoogleBooksApiKey;
      if (AppConfig.googleBooksApiKey.isNotEmpty) {
        expect(hasKey, isTrue);
      } else {
        expect(hasKey, isFalse);
      }
    });

    // BUSINESS LOGIC: Verify the constant definitions are accessible
    test('provides Supabase URL configuration', () {
      expect(AppConfig.supabaseUrl, isNotEmpty);
      expect(AppConfig.supabaseUrl, contains('supabase'));
    });

    test('provides Supabase publishable key', () {
      expect(AppConfig.supabasePublishableKey, isNotEmpty);
    });
  });
}
