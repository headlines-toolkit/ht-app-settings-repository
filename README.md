# ht_app_settings_repository

![coverage: 100%](https://img.shields.io/badge/coverage-100-green)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![License: PolyForm Free Trial](https://img.shields.io/badge/License-PolyForm%20Free%20Trial-blue)](https://polyformproject.org/licenses/free-trial/1.0.0)

A repository package for managing application settings (theme, language) built upon `ht_app_settings_client`. It provides a clean interface for accessing and modifying settings, along with reactive streams to observe changes.

## Getting Started

Add the repository to your `pubspec.yaml`:

```yaml
dependencies:
  ht_app_settings_repository:
    git:
      url: https://github.com/headlines-toolkit/ht-app-settings-repository.git
      # Use a specific ref (tag, branch, commit hash) for stability:
      # ref: main
```

Ensure you also have a dependency on a concrete implementation of `ht_app_settings_client` (e.g., `ht_app_settings_inmemory`).

## Features

*   Provides access to application display settings (`DisplaySettings`) and language (`AppLanguage`).
*   Offers reactive streams (`watchDisplaySettings`, `watchLanguage`) to listen for changes.
*   Abstracts the underlying storage mechanism via `HtAppSettingsClient`.
*   Includes methods for getting, setting, and clearing settings.

## Usage

```dart
import 'package:ht_app_settings_repository/ht_app_settings_repository.dart';
import 'package:ht_app_settings_client/ht_app_settings_client.dart'; // For concrete client/models if needed for setup
import 'package:ht_app_settings_inmemory/ht_app_settings_inmemory.dart'; // Example concrete client

void main() async {
  // 1. Create a client instance (e.g., in-memory)
  final settingsClient = HtAppSettingsInMemory();

  // 2. Create the repository instance, injecting the client and providing a user ID
  final settingsRepository = HtAppSettingsRepository(
    client: settingsClient,
    userId: 'test_user_id', // Replace with actual user ID
  );

  // 3. Listen to streams
  final displaySub = settingsRepository.watchDisplaySettings.listen((settings) {
    print('Display settings changed: ${settings.baseTheme}');
  });

  final langSub = settingsRepository.watchLanguage.listen((language) {
    print('Language changed: $language');
  });

  // 4. Get current values
  final currentSettings = settingsRepository.currentDisplaySettings;
  print('Current theme: ${currentSettings.baseTheme}');

  // 5. Update settings
  await settingsRepository.setDisplaySettings(
    currentSettings.copyWith(baseTheme: AppBaseTheme.dark),
  );

  await settingsRepository.setLanguage('es');

  // 6. Dispose when done
  // In a real app, manage disposal with your state management solution
  await Future.delayed(const Duration(seconds: 1)); // Allow streams to emit
  settingsRepository.dispose();
  displaySub.cancel();
  langSub.cancel();
}

```

## License

This package is licensed under the [PolyForm Free Trial 1.0.0](LICENSE). Please review the terms before use.
