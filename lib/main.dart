// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/database_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbService = await DatabaseService.init();

  runApp(
    ProviderScope(
      overrides: [databaseServiceProvider.overrideWithValue(dbService)],
      child: const FoodApp(),
    ),
  );
}

class FoodApp extends ConsumerWidget {
  const FoodApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Food POS',
      theme: appTheme,
      darkTheme: appThemeDark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
