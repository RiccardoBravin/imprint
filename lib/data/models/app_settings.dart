import 'package:flutter/material.dart';
import 'package:imprint/data/models/s3_config.dart';

class AppSettings {
  const AppSettings({
    this.s3Config,
    this.uiTextScaleFactor = 1.0,
    this.themeMode = ThemeMode.system,
  });

  final S3Config? s3Config;
  final double uiTextScaleFactor;
  final ThemeMode themeMode;

  static const AppSettings defaults = AppSettings();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          s3Config == other.s3Config &&
          uiTextScaleFactor == other.uiTextScaleFactor &&
          themeMode == other.themeMode;

  @override
  int get hashCode => Object.hash(s3Config, uiTextScaleFactor, themeMode);

  AppSettings copyWith({
    S3Config? s3Config,
    double? uiTextScaleFactor,
    ThemeMode? themeMode,
  }) => AppSettings(
    s3Config: s3Config ?? this.s3Config,
    uiTextScaleFactor: uiTextScaleFactor ?? this.uiTextScaleFactor,
    themeMode: themeMode ?? this.themeMode,
  );
}
