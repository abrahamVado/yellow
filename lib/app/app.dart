import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

import 'package:black/core/services/fcm_service.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    // Initialize FCM Service to create notification channels
    ref.read(fcmServiceProvider).initialize();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final theme = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Black Driver App',
      theme: theme,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.1),
          child: child!,
        );
      },
    );
  }
}
