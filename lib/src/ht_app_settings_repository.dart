import 'dart:async';

import 'package:ht_app_settings_client/ht_app_settings_client.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

/// {@template ht_app_settings_repository}
/// A repository that manages application settings.
///
/// This repository interacts with an underlying [HtAppSettingsClient]
/// to persist and retrieve settings, while providing streams to observe
/// changes reactively.
/// {@endtemplate}
class HtAppSettingsRepository {
  /// {@macro ht_app_settings_repository}
  ///
  /// Requires an instance of [HtAppSettingsClient] to handle the actual
  /// storage operations.
  HtAppSettingsRepository({
    required HtAppSettingsClient client,
  }) : _client = client {
    // Initialize streams with current values or defaults from the client.
    _initializeStreams();
  }

  final HtAppSettingsClient _client;

  // BehaviorSubjects to hold and stream the latest settings values.
  // Using BehaviorSubject ensures new listeners get the current value immediately.
  final _displaySettingsSubject =
      BehaviorSubject<DisplaySettings>.seeded(const DisplaySettings());
  final _languageSubject = BehaviorSubject<AppLanguage>();

  /// Stream of the current [DisplaySettings].
  Stream<DisplaySettings> get watchDisplaySettings =>
      _displaySettingsSubject.stream;

  /// Stream of the current [AppLanguage].
  Stream<AppLanguage> get watchLanguage => _languageSubject.stream;

  /// Gets the current [DisplaySettings] directly.
  ///
  /// Returns the latest value from the stream.
  DisplaySettings get currentDisplaySettings => _displaySettingsSubject.value;

  /// Gets the current [AppLanguage] directly.
  ///
  /// Returns the latest value from the stream.
  AppLanguage get currentLanguage => _languageSubject.value;

  // Initializes the streams by fetching initial values from the client.
  Future<void> _initializeStreams() async {
    try {
      final initialSettings = await _client.getDisplaySettings();
      // Add only if the subject hasn't been closed (e.g., by dispose)
      if (!_displaySettingsSubject.isClosed) {
        _displaySettingsSubject.add(initialSettings);
      }
    } on Exception catch (_) {
      // Keep seeded default if fetch fails. Log error in real app.
    }
    try {
      final initialLanguage = await _client.getLanguage();
      // Add only if the subject hasn't been closed
      if (!_languageSubject.isClosed) {
        _languageSubject.add(initialLanguage);
      }
    } on Exception catch (_) {
      // If fetch fails, stream remains uninitialized until setLanguage called.
      // Log error in real app. Consider adding a default language if needed.
    }
  }

  /// Retrieves the current [DisplaySettings] from the client.
  ///
  /// Note: Prefer using [watchDisplaySettings] for reactive updates or
  /// [currentDisplaySettings] for the latest cached value.
  ///
  /// Rethrows any exceptions encountered by the underlying client.
  Future<DisplaySettings> getDisplaySettings() async {
    // Although we have the stream, this method directly mirrors the client
    // API for potentially fetching the absolute latest from the source.
    final settings = await _client.getDisplaySettings();
    _displaySettingsSubject.add(settings); // Update stream just in case
    return settings;
  }

  /// Saves the provided [DisplaySettings] using the client and updates the stream.
  ///
  /// Rethrows any exceptions encountered by the underlying client.
  Future<void> setDisplaySettings(DisplaySettings settings) async {
    await _client.setDisplaySettings(settings);
    _displaySettingsSubject.add(settings);
  }

  /// Retrieves the current [AppLanguage] from the client.
  ///
  /// Note: Prefer using [watchLanguage] for reactive updates or
  /// [currentLanguage] for the latest cached value.
  ///
  /// Rethrows any exceptions encountered by the underlying client.
  Future<AppLanguage> getLanguage() async {
    // Mirrors the client API, similar to getDisplaySettings.
    final language = await _client.getLanguage();
    _languageSubject.add(language); // Update stream
    return language;
  }

  /// Saves the provided [AppLanguage] using the client and updates the stream.
  ///
  /// Rethrows any exceptions encountered by the underlying client.
  Future<void> setLanguage(AppLanguage language) async {
    await _client.setLanguage(language);
    _languageSubject.add(language);
  }

  /// Clears all settings to their defaults using the client and updates streams.
  ///
  /// Rethrows any exceptions encountered by the underlying client.
  Future<void> clearSettings() async {
    await _client.clearSettings();
    // Re-fetch the (now default) settings to update the streams
    await _initializeStreams();
  }

  /// Closes the underlying streams.
  ///
  /// Should be called when the repository is no longer needed to prevent
  /// memory leaks.
  @mustCallSuper
  void dispose() {
    _displaySettingsSubject.close();
    _languageSubject.close();
  }
}
