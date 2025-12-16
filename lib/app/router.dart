import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/verify_code_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/dashboard/presentation/screens/request_taxi_screen.dart';
import '../features/dashboard/presentation/screens/mis_viajes_screen.dart';
import '../features/dashboard/presentation/screens/account_statement_screen.dart';
import '../features/dashboard/presentation/screens/trip_tracking_screen.dart';
import '../features/payment/presentation/screens/add_card_screen.dart';
import '../features/payment/presentation/screens/payment_methods_screen.dart';



final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(-1.0, 0.0); // Slide from Left
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-code',
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return VerifyCodeScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
        routes: [
           GoRoute(
            path: 'request-taxi',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const RequestTaxiScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0); // Slide from Bottom
                const end = Offset.zero;
                const curve = Curves.ease;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(position: animation.drive(tween), child: child);
              },
            ),
          ),
           GoRoute(
            path: 'my-trips',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const MisViajesScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(-1.0, 0.0); // Slide from Left
                const end = Offset.zero;
                const curve = Curves.ease;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(position: animation.drive(tween), child: child);
              },
            ),
          ),
           GoRoute(
            path: 'account-statement',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const AccountStatementScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0); // Slide from Right
                const end = Offset.zero;
                const curve = Curves.ease;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(position: animation.drive(tween), child: child);
              },
            ),

           GoRoute(
            path: 'payment-methods',
            builder: (context, state) => const PaymentMethodsScreen(),
          ),
          GoRoute(
            path: 'trip-tracking/:tripId',
            pageBuilder: (context, state) {
              final tripIdStr = state.pathParameters['tripId'];
              final tripId = int.tryParse(tripIdStr ?? '') ?? 0;
              return CustomTransitionPage(
                key: state.pageKey,
                child: TripTrackingScreen(tripId: tripId),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                   const begin = Offset(0.0, 1.0); // Slide from Bottom
                   const end = Offset.zero;
                   const curve = Curves.ease;
                   var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                   return SlideTransition(position: animation.drive(tween), child: child);
                },
              );
            },
          ),
          GoRoute(
            path: 'add-card',
            builder: (context, state) => const AddCardScreen(),
          ),
        ],
      ),
    ],
  );
});
