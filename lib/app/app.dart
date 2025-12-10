import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

import 'package:yellow/core/services/fcm_service.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    // Initialize FCM Service
    final fcmService = ref.read(fcmServiceProvider);
    fcmService.initialize();
    
    // We can't access context or ref.read(appRouterProvider) here safely for navigation 
    // immediately in initState if the provider depends on context or other things, 
    // but appRouterProvider is just a Provider.
    final router = ref.read(appRouterProvider);
    fcmService.setupInteractedMessage(router);
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
