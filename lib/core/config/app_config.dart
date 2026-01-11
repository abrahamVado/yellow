import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yellow/core/config/env.dart';

class AppConfig {
  final Env env;

  AppConfig({required this.env});

  static const String appId = 'com.matheydriver.yellow';
  
  // App Info
  static const String appName = 'Mathey Pasajero';
  static const String version = '1.0.0';
  static const bool debug = true;
  
  // Theme Overrides
  static const Color primaryColor = Color(0xFFFFC107); // Premium Yellow
  static const Color fontColor = Color(0xFF212121); // Almost Black
  static const Color waveColor1 = Color(0xFFFFD54F);
  static const Color waveColor2 = Color(0xFFFF6F00); // Deep Amber for contrast
  
  // Texts
  static const String title = 'Mathey Pasajero';
  static const String subtitle = 'Tu viaje, tu seguridad.';
  static const String buttonText = 'CONTINUAR';
  
  static const Color buttonColor = Color(0xFF212121); // Black Buttons
  static const Color buttonTextColor = Colors.white; // White Texts
  static const String logoUrl = 'assets/images/logo_padded.jpeg';
  
  // UI Constants
  static const double borderRadius = 16.0;
  static const double defaultPadding = 20.0;
  
  // Fees
  static const double mercadoPagoFeePercentage = 0.04; // 4%
}

final appConfigProvider = Provider<AppConfig>((ref) {
  // This should ideally be initialized in main or overridden
  throw UnimplementedError('appConfigProvider must be overridden in main.dart');
});
