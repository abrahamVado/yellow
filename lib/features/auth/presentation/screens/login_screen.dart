import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../application/auth/auth_providers.dart';
import '../../../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authNotifierProvider);

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
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: SizedBox(
          width: 400,
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
                  label: 'Email or username',
                  validator: Validators.requiredField,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: passwordCtrl,
                  label: 'Password',
                  obscureText: true,
                  validator: Validators.requiredField,
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Login',
                  isLoading: state.isLoading,
                  onPressed: handleLogin,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text("Don't have an account? Register"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
