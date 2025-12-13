import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeMenuPanel extends ConsumerWidget {
  const HomeMenuPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeConfig = ref.watch(themeConfigProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // BIG MAIN ACTION: Request Taxi
            _MenuCard(
              title: 'Pedir un Taxi',
              subtitle: 'Viaja seguro y rápido',
              icon: Icons.local_taxi,
              color: themeConfig.buttonColor,
              textColor: themeConfig.buttonTextColor,
              height: 140,
              iconSize: 60,
              onTap: () => context.push('/dashboard/request-taxi'),
            ),
            const SizedBox(height: 16),
            
            // SECONDARY ACTIONS
            Row(
              children: [
                Expanded(
                  child: _MenuCard(
                    title: 'Mis Viajes',
                    subtitle: 'Historial',
                    icon: Icons.history,
                    color: Colors.white,
                    textColor: Colors.black,
                    height: 120,
                    iconSize: 32,
                    onTap: () => context.push('/dashboard/my-trips'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MenuCard(
                    title: 'Mi Cuenta',
                    subtitle: 'Pagos y más',
                    icon: Icons.account_balance_wallet,
                    color: Colors.white,
                    textColor: Colors.black,
                    height: 120,
                    iconSize: 32,
                    onTap: () => context.push('/dashboard/account-statement'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color textColor;
  final double height;
  final double iconSize;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.height,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16), // Reduced padding to prevent overflow
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Icon(icon, size: iconSize, color: textColor.withOpacity(0.8)),
                ),
                Flexible( // Added Flexible to prevent overflow
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11, // Reduced font size slightly
                          color: textColor.withOpacity(0.6),
                        ),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
