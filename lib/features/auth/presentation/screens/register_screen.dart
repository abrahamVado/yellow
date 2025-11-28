import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../application/auth/auth_providers.dart';
import '../../../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authNotifierProvider);

    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Future<void> handleRegister() async {
      if (!formKey.currentState!.validate()) return;

      final phone = phoneCtrl.text.trim();

      // Call backend to register + send SMS token
      final notifier = ref.read(authNotifierProvider.notifier);
      final ok = await notifier.registerWithPhone(
        phoneNumber: phone,
        role: 'client', // Hardcoded for Yellow App
      );

      if (ok && context.mounted) {
        // Navigate to verify-code screen
        context.go('/verify-code?phone=$phone');
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
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
                  controller: phoneCtrl,
                  label: 'Phone number',
                  validator: Validators.requiredField,
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Register with Phone',
                  isLoading: state.isLoading,
                  onPressed: handleRegister,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
