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
      backgroundColor: themeConfig.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Container(
                 padding: const EdgeInsets.all(20),
                 decoration: BoxDecoration(
                   color: Colors.white, 
                   shape: BoxShape.circle,
                   boxShadow: [
                     BoxShadow(
                       color: themeConfig.primaryColor.withOpacity(0.3),
                       blurRadius: 20,
                       offset: const Offset(0, 10),
                     )
                   ]
                 ),
                 child: Icon(Icons.lock_outline_rounded, size: 50, color: themeConfig.primaryColor),
               ),
               const SizedBox(height: 30),
               
              Card(
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.1),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Verificación',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ingresa el código enviado a tu WhatsApp/SMS\n$phone',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 15),
                        ),
                        const SizedBox(height: 32),
                        
                        TextFormField(
                          controller: codeCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: '000000',
                            filled: true,
                            fillColor: Colors.grey[50], 
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 20),
                          ),
                          validator: Validators.requiredField,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeConfig.buttonColor,
                              foregroundColor: themeConfig.buttonTextColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 4,
                              shadowColor: themeConfig.buttonColor.withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: state.isLoading ? null : handleVerify,
                            child: state.isLoading 
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                              : const Text(
                                  'VERIFICAR',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
