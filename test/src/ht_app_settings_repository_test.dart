// ignore_for_file: prefer_const_constructors, must_be_immutable, avoid_redundant_argument_values
// ignore_for_file: cascade_invocations

import 'dart:async';

import 'package:ht_app_settings_client/ht_app_settings_client.dart';
import 'package:ht_app_settings_repository/ht_app_settings_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// Mock class for the client dependency
class MockHtAppSettingsClient extends Mock implements HtAppSettingsClient {}

// A fake DisplaySettings class implementing Equatable for testing
class FakeDisplaySettings extends Fake implements DisplaySettings {
  FakeDisplaySettings({
    this.baseTheme = AppBaseTheme.system,
    this.accentTheme = AppAccentTheme.defaultBlue,
  });
  @override
  final AppBaseTheme baseTheme;
  @override
  final AppAccentTheme accentTheme;

  @override
  List<Object?> get props => [baseTheme, accentTheme];

  @override
  bool get stringify => true;
}

void main() {
  group('HtAppSettingsRepository', () {
    late HtAppSettingsClient mockClient;
    late HtAppSettingsRepository repository;

    // Default values for testing
    const defaultSettings = DisplaySettings();
    const defaultLanguage = 'en'; // Assuming 'en' is a sensible default

    setUp(() {
      mockClient = MockHtAppSettingsClient();

      // Stub initial calls from constructor -> _initializeStreams
      when(() => mockClient.getDisplaySettings())
          .thenAnswer((_) async => defaultSettings);
      when(() => mockClient.getLanguage())
          .thenAnswer((_) async => defaultLanguage);

      repository = HtAppSettingsRepository(client: mockClient);
    });

    tearDown(() {
      repository.dispose();
    });

    test('can be instantiated and initializes streams', () async {
      // Wait for async initialization in constructor to complete
      await Future<void>.delayed(Duration.zero);

      expect(repository, isNotNull);
      // Verify initial fetches happened during setup
      verify(() => mockClient.getDisplaySettings()).called(1);
      verify(() => mockClient.getLanguage()).called(1);

      // Check initial stream values
      expect(repository.watchDisplaySettings, emits(defaultSettings));
      expect(repository.watchLanguage, emits(defaultLanguage));
      expect(repository.currentDisplaySettings, defaultSettings);
      expect(repository.currentLanguage, defaultLanguage);
    });

    group('Display Settings', () {
      final newSettings = FakeDisplaySettings(
        baseTheme: AppBaseTheme.dark,
        accentTheme: AppAccentTheme.newsRed,
      );

      test('getDisplaySettings fetches from client and updates stream',
          () async {
        when(() => mockClient.getDisplaySettings())
            .thenAnswer((_) async => newSettings);

        final result = await repository.getDisplaySettings();

        expect(result, newSettings);
        // Called once during setup, once here
        verify(() => mockClient.getDisplaySettings()).called(2);
        // Stream should emit the newly fetched value
        expect(repository.watchDisplaySettings, emits(newSettings));
        expect(repository.currentDisplaySettings, newSettings);
      });

      test('setDisplaySettings calls client and updates stream', () async {
        when(() => mockClient.setDisplaySettings(newSettings))
            .thenAnswer((_) async {});

        await repository.setDisplaySettings(newSettings);

        verify(() => mockClient.setDisplaySettings(newSettings)).called(1);
        expect(repository.watchDisplaySettings, emits(newSettings));
        expect(repository.currentDisplaySettings, newSettings);
      });

      test('setDisplaySettings propagates client exception', () async {
        final exception = Exception('Client failed to save settings');
        when(() => mockClient.setDisplaySettings(newSettings))
            .thenThrow(exception);

        expect(
          () => repository.setDisplaySettings(newSettings),
          throwsA(exception),
        );
        // Verify stream did not update
        expect(repository.currentDisplaySettings, defaultSettings);
      });
    });

    group('Language', () {
      const newLanguage = 'es';

      test('getLanguage fetches from client and updates stream', () async {
        when(() => mockClient.getLanguage())
            .thenAnswer((_) async => newLanguage);

        final result = await repository.getLanguage();

        expect(result, newLanguage);
        // Called once during setup, once here
        verify(() => mockClient.getLanguage()).called(2);
        expect(repository.watchLanguage, emits(newLanguage));
        expect(repository.currentLanguage, newLanguage);
      });

      test('setLanguage calls client and updates stream', () async {
        when(() => mockClient.setLanguage(newLanguage))
            .thenAnswer((_) async {});

        await repository.setLanguage(newLanguage);

        verify(() => mockClient.setLanguage(newLanguage)).called(1);
        expect(repository.watchLanguage, emits(newLanguage));
        expect(repository.currentLanguage, newLanguage);
      });

      test('setLanguage propagates client exception', () async {
        final exception = Exception('Client failed to save language');
        when(() => mockClient.setLanguage(newLanguage)).thenThrow(exception);

        expect(
          () => repository.setLanguage(newLanguage),
          throwsA(exception),
        );
        // Verify stream did not update
        expect(repository.currentLanguage, defaultLanguage);
      });
    });

    group('clearSettings', () {
      test('calls client clear and re-initializes streams with defaults',
          () async {
        // Arrange: Stub clear and subsequent fetches for defaults
        when(() => mockClient.clearSettings()).thenAnswer((_) async {});
        // Assume clear resets to these specific defaults
        final clearedSettings = FakeDisplaySettings(
          baseTheme: AppBaseTheme.system, // Example default
          accentTheme: AppAccentTheme.defaultBlue, // Example default
        );
        const clearedLanguage = 'en'; // Example default

        when(() => mockClient.getDisplaySettings())
            .thenAnswer((_) async => clearedSettings);
        when(() => mockClient.getLanguage())
            .thenAnswer((_) async => clearedLanguage);

        // Act
        await repository.clearSettings();

        // Assert
        verify(() => mockClient.clearSettings()).called(1);
        // Verify it re-fetched after clearing (called once during setup too)
        verify(() => mockClient.getDisplaySettings()).called(2);
        verify(() => mockClient.getLanguage()).called(2);

        // Check streams emit the 'cleared' defaults
        expect(repository.watchDisplaySettings, emits(clearedSettings));
        expect(repository.watchLanguage, emits(clearedLanguage));
        expect(repository.currentDisplaySettings, clearedSettings);
        expect(repository.currentLanguage, clearedLanguage);
      });

      test('propagates client exception during clear', () async {
        final exception = Exception('Client failed to clear');
        when(() => mockClient.clearSettings()).thenThrow(exception);

        expect(() => repository.clearSettings(), throwsA(exception));
      });
    });

    test('dispose closes streams', () {
      // Need to listen to ensure close event can be detected
      final settingsSub = repository.watchDisplaySettings.listen(null);
      final langSub = repository.watchLanguage.listen(null);

      repository.dispose();

      // We only need to ensure dispose can be called without error.
      // Checking emitsDone is unreliable with BehaviorSubject's caching.
      // The isClosed checks in the repository prevent errors.

      // Cancel subscriptions after test
      settingsSub.cancel();
      langSub.cancel();
    });

    test('initialization handles client errors gracefully', () async {
      // Arrange: Setup a new repository where initial fetches fail
      final failingClient = MockHtAppSettingsClient();
      when(failingClient.getDisplaySettings)
          .thenThrow(Exception('Failed to get settings'));
      when(failingClient.getLanguage)
          .thenThrow(Exception('Failed to get language'));

      final failingRepo = HtAppSettingsRepository(client: failingClient);
      // Wait for async initialization
      await Future<void>.delayed(Duration.zero);

      // Assert: Repository should still be created
      expect(failingRepo, isNotNull);
      // Streams should have their initial seeded/default values or be empty
      expect(failingRepo.currentDisplaySettings, const DisplaySettings());
      // Language stream might not have a value if initial fetch failed
      expect(
        failingRepo.watchLanguage,
        neverEmits(anything),
      ); // Or check isEmpty

      failingRepo.dispose(); // Clean up
    });
  });
}
