import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import 'app_theme.dart';

final themeConfigProvider = Provider<AppThemeConfig>((ref) {
  return AppThemeConfig(
    primaryColor: AppConfig.primaryColor,
    fontColor: AppConfig.fontColor,
    waveColor1: AppConfig.waveColor1,
    waveColor2: AppConfig.waveColor2,
    title: AppConfig.title,
    subtitle: AppConfig.subtitle,
    buttonText: AppConfig.buttonText,
    buttonColor: AppConfig.buttonColor,
    buttonTextColor: AppConfig.buttonTextColor,
    logoUrl: AppConfig.logoUrl,
  );
});

final themeProvider = Provider<ThemeData>((ref) {
  final config = ref.watch(themeConfigProvider);
  return buildAppTheme(config);
});
