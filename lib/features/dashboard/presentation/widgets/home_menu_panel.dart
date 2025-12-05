import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yellow/features/dashboard/presentation/screens/request_taxi_screen.dart';
import 'package:yellow/features/dashboard/presentation/screens/my_trips_screen.dart';
import 'package:yellow/features/dashboard/presentation/screens/account_statement_screen.dart';

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
                Navigator.of(context).push(_createRoute(const RequestTaxiScreen(), const Offset(0, 1))); // Slide from Bottom
              },
            ),
            const Divider(),
            _MenuOption(
              icon: Icons.history,
              label: 'Mis viajes',
              onTap: () {
                Navigator.of(context).push(_createRoute(const MyTripsScreen(), const Offset(-1, 0))); // Slide from Left
              },
            ),
            const Divider(),
            _MenuOption(
              icon: Icons.account_balance_wallet,
              label: 'Estado de cuenta',
              onTap: () {
                Navigator.of(context).push(_createRoute(const AccountStatementScreen(), const Offset(1, 0))); // Slide from Right
              },
            ),
          ],
        ),
      ),
    );
  }

  Route _createRoute(Widget page, Offset beginOffset) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = beginOffset;
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
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
