import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yellow/core/config/env.dart';

class AppConfig {
  final Env env;

  AppConfig({required this.env});

  static const String appId = 'com.matheydriver.yellow';
  
  // Colors
  static const Color primaryColor = Color(0xFFfafaf8);
  static const Color fontColor = Color(0xFFFFFFFF);
  static const Color waveColor1 = Color(0xFFfed26c);
  static const Color waveColor2 = Color(0xFFffb300);
  static const Color buttonColor = Color(0xFFf9b419);
  static const Color buttonTextColor = Color(0xFF000000);

  // Text
  static const String title = 'Bienvenido';
  static const String subtitle = 'Experimenta una nueva manera de transporte';
  static const String buttonText = 'Siguiente';

  // Assets
  static const String logoUrl = 'assets/images/logo_padded.jpeg';
}

final appConfigProvider = Provider<AppConfig>((ref) {
  // This should ideally be initialized in main or overridden
  throw UnimplementedError('appConfigProvider must be overridden in main.dart');
});
