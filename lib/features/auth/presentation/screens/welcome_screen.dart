import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/theme_provider.dart';
import '../../../../core/config/env.dart';
import '../widgets/auth_wave_background.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(themeConfigProvider);

    return AuthWaveBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          if (config.logoUrl.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Image.asset(
                  config.logoUrl,
                  height: 360, // Increased by 50% from 240
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: config.fontColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  config.subtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: config.fontColor,
                      ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: config.buttonColor,
                  foregroundColor: config.buttonTextColor,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                label: Text(config.buttonText),
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  context.go('/login');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
