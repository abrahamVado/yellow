import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemeConfig {
  final Color primaryColor;
  final Color secondaryFontColor;
  final Color fontColor;
  final Color waveColor1;
  final Color waveColor2;
  final String title;
  final String subtitle;
  final String buttonText;
  final Color buttonColor;
  final Color buttonTextColor;
  
  // Custom getters for specific UI elements if needed, or aliases
  Color get accentColor => secondaryFontColor; // Alias/Fallback
  Color get scaffoldBackgroundColor => const Color(0xFFF8F9FA);

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
    this.secondaryFontColor = Colors.grey,
    this.logoUrl = '',
  });

  factory AppThemeConfig.fallback() {
    return AppThemeConfig(
      primaryColor: const Color(0xFFFBC02D),
      fontColor: Colors.black,
      waveColor1: const Color(0xFFFFCA28),
      waveColor2: const Color(0xFFFFB300),
      title: 'Bienvenido',
      subtitle: 'Transporte Premium',
      buttonText: 'Continuar',
      buttonColor: const Color(0xFFFFC107),
      buttonTextColor: Colors.black,
    );
  }
}

ThemeData buildAppTheme(AppThemeConfig config) {
  return ThemeData(
    primaryColor: config.primaryColor,
    scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Off-white for cleaner look
    
    // Modern Typography
    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: config.fontColor,
      displayColor: config.fontColor,
    ),
    
    // Input Decoration (Rounded & Clean)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: config.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      labelStyle: TextStyle(color: config.secondaryFontColor),
      hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
    ),

    // Button Theme (Rounded & Shadow)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: config.buttonColor,
        foregroundColor: config.buttonTextColor,
        elevation: 4,
        shadowColor: config.buttonColor.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),
    
    colorScheme: ColorScheme.fromSeed(
      seedColor: config.primaryColor,
      primary: config.primaryColor,
      secondary: config.waveColor1,
    ),
    
    useMaterial3: true,
  );
}
