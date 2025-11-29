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
      primaryColor: _hexToColor(data['primary_color'] ?? '#FFD700'),
      fontColor: _hexToColor(data['font_color'] ?? '#000000'),
      waveColor1: _hexToColor(data['wave_color_1'] ?? '#FFD700'),
      waveColor2: _hexToColor(data['wave_color_2'] ?? '#FFA000'),
      title: data['title'] ?? 'Welcome',
      subtitle: data['subtitle'] ?? 'Experience the new way of authentication.',
      buttonText: data['button_text'] ?? 'Continue',
      buttonColor: _hexToColor(data['button_color'] ?? '#FFD700'),
      buttonTextColor: _hexToColor(data['button_text_color'] ?? '#000000'),
      logoUrl: data['logo_url'] ?? '',
    );
  } catch (e, stack) {
    debugPrint('Error loading theme config: $e');
    debugPrint('Stack trace: $stack');
    return AppThemeConfig.fallback();
  }
});

Color _hexToColor(String hex) {
  hex = hex.replaceAll('#', '');
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  return Color(int.parse(hex, radix: 16));
}
