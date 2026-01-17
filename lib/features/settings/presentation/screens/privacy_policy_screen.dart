import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/theme_provider.dart';

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeConfig = ref.watch(themeConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidad'),
        backgroundColor: themeConfig.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Política de Privacidad',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Su privacidad es importante para nosotros. Esta política explica cómo recopilamos, usamos y protegemos su información.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildSection(
              '1. Información Recopilada',
              'Recopilamos información que usted nos proporciona directamente, como su nombre, número de teléfono y correo electrónico, así como información sobre su ubicación durante el uso de la aplicación.',
            ),
            _buildSection(
              '2. Uso de la Información',
              'Utilizamos su información para facilitar los servicios de transporte, procesar pagos, mejorar la seguridad y comunicarnos con usted.',
            ),
            _buildSection(
              '3. Compartir Información',
              'Podemos compartir su información con los conductores para facilitar el servicio. No vendemos su información personal a terceros.',
            ),
            _buildSection(
              '4. Sus Derechos',
              'Usted tiene derecho a acceder, corregir o eliminar su información personal en cualquier momento a través de la configuración de la aplicación.',
            ),
             const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
