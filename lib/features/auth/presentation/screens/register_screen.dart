import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/theme_provider.dart';

import '../../../../application/auth/auth_providers.dart';
import '../../../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authNotifierProvider);
    final themeConfig = ref.watch(themeConfigProvider).valueOrNull;

    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Future<void> handleRegister() async {
      if (!formKey.currentState!.validate()) return;

      final phone = phoneCtrl.text.trim();

      // Call backend to register + send SMS token
      final notifier = ref.read(authNotifierProvider.notifier);
      final ok = await notifier.registerWithPhone(
        phoneNumber: phone,
        role: 'driver', // Hardcoded for Black App
      );

      if (ok && context.mounted) {
        // Navigate to verify-code screen
        context.go('/verify-code?phone=$phone');
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Registrarse')),
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
                    if (state.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    AppTextField(
                      controller: phoneCtrl,
                      label: 'Número de teléfono',
                      validator: Validators.requiredField,
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Registrarse con teléfono',
                      isLoading: state.isLoading,
                      onPressed: handleRegister,
                      backgroundColor: themeConfig?.buttonColor,
                      foregroundColor: themeConfig?.buttonTextColor,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('¿Ya tienes una cuenta? Iniciar sesión'),
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
