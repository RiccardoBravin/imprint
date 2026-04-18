import 'dart:developer' as dev;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imprint/app.dart';
import 'package:imprint/core/constants.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    dev.log(details.exceptionAsString(), name: 'imprint', stackTrace: details.stack);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    dev.log('$error', name: 'imprint', stackTrace: stack, error: error);
    return false;
  };

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    minimumSize: kMinWindowSize,
    size: Size(1280, 800),
    center: true,
    title: kAppName,
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: ImprintApp()));
}
