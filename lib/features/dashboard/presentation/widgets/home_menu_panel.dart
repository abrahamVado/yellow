import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeMenuPanel extends StatelessWidget {
  const HomeMenuPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MenuOption(
              icon: Icons.local_taxi,
              label: 'Pedir un taxi',
              onTap: () {
                context.push('/dashboard/request-taxi');
              },
            ),
            const Divider(),
            _MenuOption(
              icon: Icons.history,
              label: 'Mis viajes',
              onTap: () {
                context.push('/dashboard/my-trips');
              },
            ),
            const Divider(),
            _MenuOption(
              icon: Icons.account_balance_wallet,
              label: 'Estado de cuenta',
              onTap: () {
                context.push('/dashboard/account-statement');
              },
            ),
          ],
        ),
      ),
    );
  }

  // Route builder removed as we are using GoRouter now
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.amber), // Yellow Taxi color
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
