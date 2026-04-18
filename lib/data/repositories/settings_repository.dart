import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:imprint/data/models/app_settings.dart';
import 'package:imprint/data/models/s3_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Non-sensitive keys — remain in SharedPreferences.
const _kRecentFiles = 'app.recentFiles';
const _kUiTextScaleFactor = 'app.uiTextScaleFactor';
const _kThemeMode = 'app.themeMode';

// Sensitive keys — stored in platform secure storage.
const _kS3Endpoint = 'app.s3.endpoint';
const _kS3Bucket = 'app.s3.bucket';
const _kS3AccessKey = 'app.s3.accessKey';
const _kS3SecretKey = 'app.s3.secretKey';

const _secure = FlutterSecureStorage();

class SettingsRepository {
  SettingsRepository._();

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Migrate any plaintext S3 credentials left from a previous build.
    await _migrateS3IfNeeded(prefs);

    final endpoint = await _secureRead(_kS3Endpoint, prefs);
    final bucket = await _secureRead(_kS3Bucket, prefs);
    final accessKey = await _secureRead(_kS3AccessKey, prefs);
    final secretKey = await _secureRead(_kS3SecretKey, prefs);

    S3Config? s3Config;
    if (endpoint != null && bucket != null && accessKey != null && secretKey != null) {
      s3Config = S3Config(
        endpoint: endpoint,
        bucket: bucket,
        accessKey: accessKey,
        secretKey: secretKey,
      );
    }

    final uiTextScaleFactor = prefs.getDouble(_kUiTextScaleFactor) ?? 1.0;

    final themeMode = switch (prefs.getString(_kThemeMode)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return AppSettings(
      s3Config: s3Config,
      uiTextScaleFactor: uiTextScaleFactor,
      themeMode: themeMode,
    );
  }

  static Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();

    if (settings.s3Config case final s3?) {
      await _secureWrite(_kS3Endpoint, s3.endpoint, prefs);
      await _secureWrite(_kS3Bucket, s3.bucket, prefs);
      await _secureWrite(_kS3AccessKey, s3.accessKey, prefs);
      await _secureWrite(_kS3SecretKey, s3.secretKey, prefs);
    } else {
      await _secureDelete(_kS3Endpoint, prefs);
      await _secureDelete(_kS3Bucket, prefs);
      await _secureDelete(_kS3AccessKey, prefs);
      await _secureDelete(_kS3SecretKey, prefs);
    }

    await prefs.setDouble(_kUiTextScaleFactor, settings.uiTextScaleFactor);

    final themeModeStr = switch (settings.themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await prefs.setString(_kThemeMode, themeModeStr);
  }

  // ---------------------------------------------------------------------------
  // Recent files
  // ---------------------------------------------------------------------------

  static Future<List<String>> loadRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kRecentFiles);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw) as List);
  }

  static Future<void> addRecentFile(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final files = await loadRecentFiles();
    files.remove(path);
    files.insert(0, path);
    final trimmed = files.take(10).toList();
    await prefs.setString(_kRecentFiles, jsonEncode(trimmed));
  }

  static Future<void> removeRecentFile(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final files = await loadRecentFiles();
    files.remove(path);
    await prefs.setString(_kRecentFiles, jsonEncode(files));
  }

  // ---------------------------------------------------------------------------
  // One-time migration: move plaintext S3 keys → secure storage
  // ---------------------------------------------------------------------------

  static Future<void> _migrateS3IfNeeded(SharedPreferences prefs) async {
    final legacyEndpoint = prefs.getString(_kS3Endpoint);
    if (legacyEndpoint == null) return; // nothing to migrate

    try {
      await _secure.write(key: _kS3Endpoint, value: legacyEndpoint);
      await _secure.write(key: _kS3Bucket, value: prefs.getString(_kS3Bucket) ?? '');
      await _secure.write(key: _kS3AccessKey, value: prefs.getString(_kS3AccessKey) ?? '');
      await _secure.write(key: _kS3SecretKey, value: prefs.getString(_kS3SecretKey) ?? '');

      await prefs.remove(_kS3Endpoint);
      await prefs.remove(_kS3Bucket);
      await prefs.remove(_kS3AccessKey);
      await prefs.remove(_kS3SecretKey);
    } on PlatformException {
      // Secure storage unavailable; leave values in shared_preferences where
      // _secureRead will find them on the next load.
    }
  }

  // ---------------------------------------------------------------------------
  // Secure storage helpers with shared_preferences fallback
  // ---------------------------------------------------------------------------

  static Future<String?> _secureRead(String key, SharedPreferences prefs) async {
    try {
      return await _secure.read(key: key);
    } on PlatformException {
      return prefs.getString(key);
    }
  }

  static Future<void> _secureWrite(String key, String value, SharedPreferences prefs) async {
    try {
      await _secure.write(key: key, value: value);
      await prefs.remove(key); // clear any previous fallback value
    } on PlatformException {
      await prefs.setString(key, value);
    }
  }

  static Future<void> _secureDelete(String key, SharedPreferences prefs) async {
    try {
      await _secure.delete(key: key);
    } on PlatformException {
      // best effort
    }
    await prefs.remove(key); // also remove any fallback value
  }
}
