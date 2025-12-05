import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../application/auth/auth_providers.dart';
import '../../../../app/theme/theme_provider.dart';
import '../../../../core/config/env.dart';
import '../widgets/auth_wave_background.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';



class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isCodeSent = false;
  bool _isLoginMode = false; // Default to Register mode

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    // Split name only if in register mode
    String firstName = '';
    String lastName = '';
    String email = '';
    
    if (!_isLoginMode) {
      final fullName = _nameController.text.trim();
      if (fullName.isNotEmpty) {
        final parts = fullName.split(' ');
        firstName = parts.first;
        if (parts.length > 1) {
          lastName = parts.sublist(1).join(' ');
        }
      }
      email = _emailController.text.trim();
    }

    // Trigger registration/SMS sending
    // The backend handles "login" via the same endpoint (finds user by phone)
    final success = await ref.read(authNotifierProvider.notifier).registerWithPhone(
          phoneNumber: phone,
          role: 'client',
          firstName: firstName,
          lastName: lastName,
          email: email,
        );

    if (success) {
      setState(() {
        _isCodeSent = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Código enviado! Revisa tus SMS.')),
        );
      }
    }
  }

  Future<void> _verifyCode() async {
    final phone = _phoneController.text.trim();
    final code = _otpController.text.trim();
    if (phone.isEmpty || code.isEmpty) return;

    final success = await ref
        .read(authNotifierProvider.notifier)
        .verifySmsCode(phone: phone, code: code);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Inicio de Sesión Exitoso!')),
        );
        context.go('/dashboard');
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final themeConfig = ref.watch(themeConfigProvider);
    
    final primaryColor = themeConfig.primaryColor;
    final buttonColor = themeConfig.buttonColor;
    final buttonTextColor = themeConfig.buttonTextColor;

    return AuthWaveBackground(
      child: Stack(
        children: [
          // Back Button
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => context.go('/welcome'),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (themeConfig.logoUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Image.asset(
                        themeConfig.logoUrl,
                        height: 225, // Increased by 50% from 150
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  Card(
                    elevation: 8,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and Toggle
                          // Title and Toggle
                          if (!_isCodeSent)
                            Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _isLoginMode = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: !_isLoginMode ? buttonColor : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Crear Cuenta',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: !_isLoginMode ? buttonTextColor : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _isLoginMode = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: _isLoginMode ? buttonColor : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Iniciar Sesión',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _isLoginMode ? buttonTextColor : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Text(
                                'Verificación',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),

                          if (authState.errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                authState.errorMessage!,
                                style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                              ),
                            ),

                          if (!_isCodeSent) ...[
                            if (!_isLoginMode) ...[
                              // Name Field
                              Text('Nombre Completo', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _nameController,
                                style: const TextStyle(color: Colors.black),
                                decoration: const InputDecoration(
                                  hintText: 'Juan Pérez',
                                  prefixIcon: Icon(Icons.person_outline, size: 18),
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Email Field
                              Text('Correo Electrónico', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.black),
                                decoration: const InputDecoration(
                                  hintText: 'juan@ejemplo.com',
                                  prefixIcon: Icon(Icons.email_outlined, size: 18),
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Phone Field
                            Text('Número de Teléfono', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                hintText: '+52 555 123 4567',
                                prefixIcon: Icon(FontAwesomeIcons.whatsapp, size: 18, color: Colors.green),
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Te enviaremos un código de verificación por WhatsApp.',
                                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // OTP Field
                            Text('Ingresa el Código SMS', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                hintText: '123456',
                                prefixIcon: Icon(Icons.lock_clock, size: 18),
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isCodeSent = false;
                                  _otpController.clear();
                                });
                              },
                              child: Text('Cambiar Número', style: TextStyle(color: buttonColor)),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Action Button
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
                              onPressed: authState.isLoading
                                  ? null
                                  : (_isCodeSent ? _verifyCode : _sendCode),
                              child: authState.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      _isCodeSent 
                                        ? 'Verificar Código' 
                                        : (_isLoginMode ? 'Iniciar Sesión' : 'Crear Cuenta'),
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                            ),
                          ),
                          
                          if (!_isCodeSent) ...[
                            // No Google Sign In button anymore
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
