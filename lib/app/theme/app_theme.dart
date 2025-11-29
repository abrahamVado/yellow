import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemeConfig {
  final Color primaryColor;
  final Color fontColor;
  final Color waveColor1;
  final Color waveColor2;
  final String title;
  final String subtitle;
  final String buttonText;
  final Color buttonColor;
  final Color buttonTextColor;

  final String logoUrl;

  AppThemeConfig({
    required this.primaryColor,
    required this.fontColor,
    required this.waveColor1,
    required this.waveColor2,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.buttonColor,
    required this.buttonTextColor,
    this.logoUrl = '',
  });

  factory AppThemeConfig.fallback() {
    return AppThemeConfig(
      primaryColor: Colors.black,
      fontColor: Colors.white,
      waveColor1: const Color(0xFFFF7C7C),
      waveColor2: const Color(0xFFFF8D8D),
      title: 'Welcome',
      subtitle: 'Experience the new way of authentication.',
      buttonText: 'Continue',
      buttonColor: const Color(0xFFFF7C7C),
      buttonTextColor: Colors.white,
    );
  }
}

ThemeData buildAppTheme(AppThemeConfig config) {
  return ThemeData(
    primaryColor: config.primaryColor,
    scaffoldBackgroundColor: config.primaryColor,
    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: config.fontColor,
      displayColor: config.fontColor,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: config.primaryColor,
    ),
  );
}
