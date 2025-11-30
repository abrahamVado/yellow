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
    final theme = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Black Driver App',
      theme: theme,
      routerConfig: router,
    );
  }
}
