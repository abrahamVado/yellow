import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeConfigAsync = ref.watch(themeConfigProvider);

    return themeConfigAsync.when(
      data: (config) => MaterialApp.router(
        title: 'Yellow Rider App',
        theme: buildAppTheme(config),
        routerConfig: router,
      ),
      loading: () => const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator()))),
      error: (err, stack) => MaterialApp.router(
        title: 'Yellow Rider App',
        theme: buildAppTheme(AppThemeConfig.fallback()), // Fallback
        routerConfig: router,
      ),
    );
  }
}
