import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/theme_provider.dart';

import '../../../../application/auth/auth_providers.dart';
import '../../../../../core/utils/validators.dart';

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authNotifierProvider);
    final themeConfig = ref.watch(themeConfigProvider).valueOrNull;
    final buttonColor = themeConfig?.buttonColor ?? Colors.black;
    final buttonTextColor = themeConfig?.buttonTextColor ?? Colors.white;

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Registrarse',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 40,
                      height: 3,
                      color: buttonColor,
                    ),
                    const SizedBox(height: 24),

                    if (state.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          state.errorMessage!,
                          style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                        ),
                      ),

                    // Name Field (Visual Only)
                    Text('Nombre completo', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                    const SizedBox(height: 4),
                    const TextField(
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Juan Pérez',
                        prefixIcon: Icon(Icons.person_outline, size: 18),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email Field (Visual Only)
                    Text('Correo electrónico', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                    const SizedBox(height: 4),
                    const TextField(
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'juan@ejemplo.com',
                        prefixIcon: Icon(Icons.email_outlined, size: 18),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone Field
                    Text('Número de teléfono', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: phoneCtrl,
                      validator: Validators.requiredField,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        hintText: '+52 555 123 4567',
                        prefixIcon: Icon(Icons.phone_android, size: 18),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: buttonTextColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: state.isLoading ? null : handleRegister,
                        child: state.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Registrarse con teléfono',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('¿Ya tienes una cuenta? Iniciar sesión'),
                      ),
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
