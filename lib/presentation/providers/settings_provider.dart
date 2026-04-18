import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imprint/data/models/app_settings.dart';
import 'package:imprint/data/repositories/settings_repository.dart';

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _load();
    return AppSettings.defaults;
  }

  Future<void> _load() async {
    try {
      state = await SettingsRepository.load();
    } catch (e, stack) {
      dev.log('Failed to load settings', name: 'imprint', error: e, stackTrace: stack);
    }
  }

  Future<void> update(AppSettings settings) async {
    state = settings;
    await SettingsRepository.save(settings);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

// ---------------------------------------------------------------------------
// Recent files — loaded on demand, refreshed after open/save operations
// ---------------------------------------------------------------------------

final recentFilesProvider = FutureProvider<List<String>>(
  (_) => SettingsRepository.loadRecentFiles(),
);
