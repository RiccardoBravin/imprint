import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imprint/presentation/providers/settings_provider.dart';
import 'package:imprint/presentation/screens/home_screen.dart';

class ImprintApp extends ConsumerWidget {
  const ImprintApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (themeMode, uiTextScaleFactor) = ref.watch(
      settingsProvider.select((s) => (s.themeMode, s.uiTextScaleFactor)),
    );

    return MaterialApp(
      title: 'imprint',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF15284D),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF15284D),
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF2C2C30),
          onSurface: const Color(0xFFE4E2E6),
        ),
        useMaterial3: true,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(uiTextScaleFactor),
        ),
        child: child!,
      ),
      home: const HomeScreen(),
    );
  }
}
