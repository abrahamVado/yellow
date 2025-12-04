import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/theme_provider.dart';

import '../../../../application/auth/auth_providers.dart';
import '../../../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class VerifyCodeScreen extends ConsumerWidget {
  final String phone;

  const VerifyCodeScreen({super.key, required this.phone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authNotifierProvider);
    final themeConfig = ref.watch(themeConfigProvider);

    final codeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Future<void> handleVerify() async {
      if (!formKey.currentState!.validate()) return;

      final ok = await ref
          .read(authNotifierProvider.notifier)
          .verifySmsCode(phone: phone, code: codeCtrl.text.trim());

      if (ok && context.mounted) {
        context.go('/dashboard');
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Verificar teléfono')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Enviamos un código a $phone',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: codeCtrl,
                      label: 'Código de verificación',
                      validator: Validators.requiredField,
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Verificar',
                      isLoading: state.isLoading,
                      onPressed: handleVerify,
                      backgroundColor: themeConfig.buttonColor,
                      foregroundColor: themeConfig.buttonTextColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
