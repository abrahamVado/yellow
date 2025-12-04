import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  const appId = 'com.matheydriver.yellow';
  const apiUrl = 'https://api.softwaremia.com/api/settings/$appId';
  const targetFile = 'lib/core/config/app_config.dart';

  print('Fetching configuration for $appId from $apiUrl...');

  try {
    final request = await HttpClient().getUrl(Uri.parse(apiUrl));
    final response = await request.close();

    if (response.statusCode != 200) {
      throw Exception('Failed to load settings: ${response.statusCode}');
    }

    final responseBody = await response.transform(utf8.decoder).join();
    final jsonResponse = json.decode(responseBody);
    final data = jsonResponse['data'];

    print('Configuration fetched successfully.');

    // Download Logo
    final logoUrl = data['logo_url'];
    if (logoUrl != null && logoUrl.toString().isNotEmpty) {
      await _downloadLogo(logoUrl.toString());
    }

    print('Generating $targetFile...');

    final content = _generateAppConfig(data, appId);
    await File(targetFile).writeAsString(content);

    print('Configuration updated successfully!');
  } catch (e) {
    print('Error fetching configuration: $e');
    exit(1);
  }
}

Future<void> _downloadLogo(String url) async {
  try {
    final fullUrl = url.startsWith('http') ? url : 'https://api.softwaremia.com$url';
    print('Downloading logo from $fullUrl...');
    
    final request = await HttpClient().getUrl(Uri.parse(fullUrl));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final bytes = await response.expand((chunk) => chunk).toList();
      await File('assets/images/logo.jpeg').writeAsBytes(bytes);
      print('Logo downloaded to assets/images/logo.jpeg');
    } else {
      print('Failed to download logo: ${response.statusCode}');
    }
  } catch (e) {
    print('Error downloading logo: $e');
  }
}

String _generateAppConfig(Map<String, dynamic> data, String appId) {
  return '''
import 'package:flutter/material.dart';

class AppConfig {
  static const String appId = '$appId';
  
  // Colors
  static const Color primaryColor = Color(${_parseColor(data['primary_color'])});
  static const Color fontColor = Color(${_parseColor(data['font_color'])});
  static const Color waveColor1 = Color(${_parseColor(data['wave_color_1'])});
  static const Color waveColor2 = Color(${_parseColor(data['wave_color_2'])});
  static const Color buttonColor = Color(${_parseColor(data['button_color'])});
  static const Color buttonTextColor = Color(${_parseColor(data['button_text_color'])});

  // Text
  static const String title = '${_escapeString(data['title'] ?? 'Welcome')}';
  static const String subtitle = '${_escapeString(data['subtitle'] ?? 'Experience the new way of authentication.')}';
  static const String buttonText = '${_escapeString(data['button_text'] ?? 'Continue')}';

  // Assets
  static const String logoUrl = 'assets/images/logo_padded.jpeg';
}
''';
}

String _parseColor(String? hexString) {
  if (hexString == null || hexString.isEmpty) return '0xFF000000';
  var hex = hexString.replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  return '0x$hex';
}

String _escapeString(String value) {
  return value.replaceAll("'", "\\'");
}
