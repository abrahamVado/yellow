import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/theme_provider.dart';

import '../../../../application/auth/auth_providers.dart';
import '../../../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authNotifierProvider);
    final themeConfig = ref.watch(themeConfigProvider).valueOrNull;

    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    void handleLogin() {
      if (!formKey.currentState!.validate()) return;
      ref.read(authNotifierProvider.notifier).login(
            username: usernameCtrl.text.trim(),
            password: passwordCtrl.text.trim(),
          );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
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
                      controller: usernameCtrl,
                      label: 'Correo o usuario',
                      validator: Validators.requiredField,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: passwordCtrl,
                      label: 'Contraseña',
                      obscureText: true,
                      validator: Validators.requiredField,
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Iniciar Sesión',
                      isLoading: state.isLoading,
                      onPressed: handleLogin,
                      backgroundColor: themeConfig?.buttonColor,
                      foregroundColor: themeConfig?.buttonTextColor,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text("¿No tienes cuenta? Regístrate"),
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
