import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      appBar: AppBar(title: const Text('Verify phone')),
      body: Center(
        child: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('We sent a code to $phone'),
                const SizedBox(height: 16),
                AppTextField(
                  controller: codeCtrl,
                  label: 'Verification code',
                  validator: Validators.requiredField,
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Verify',
                  isLoading: state.isLoading,
                  onPressed: handleVerify,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
