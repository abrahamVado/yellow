import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import 'app_theme.dart';

final themeConfigProvider = FutureProvider<AppThemeConfig>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('/api/settings/com.yamato.yellow');
    final json = response.data as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;
    
    return AppThemeConfig(
      primaryColor: _hexToColor(data['primary_color'] ?? '#000000'),
      fontColor: _hexToColor(data['font_color'] ?? '#FFFFFF'),
      waveColor1: _hexToColor(data['wave_color_1'] ?? '#FF7C7C'),
      waveColor2: _hexToColor(data['wave_color_2'] ?? '#FF8D8D'),
      title: data['title'] ?? 'Welcome',
      subtitle: data['subtitle'] ?? 'Experience the new way of authentication.',
      buttonText: data['button_text'] ?? 'Continue',
      buttonColor: _hexToColor(data['button_color'] ?? '#FF7C7C'),
      buttonTextColor: _hexToColor(data['button_text_color'] ?? '#FFFFFF'),
      logoUrl: data['logo_url'] ?? '',
    );
  } catch (e, stack) {
    debugPrint('Error loading theme config: $e');
    debugPrint('Stack trace: $stack');
    return AppThemeConfig.fallback();
  }
});

final themeProvider = Provider<ThemeData>((ref) {
  final configAsync = ref.watch(themeConfigProvider);
  return configAsync.when(
    data: (config) => buildAppTheme(config),
    loading: () => buildAppTheme(AppThemeConfig.fallback()),
    error: (_, __) => buildAppTheme(AppThemeConfig.fallback()),
  );
});

Color _hexToColor(String hex) {
  hex = hex.replaceAll('#', '');
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  return Color(int.parse(hex, radix: 16));
}
