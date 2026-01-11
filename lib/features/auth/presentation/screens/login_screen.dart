import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  Future<void> _handleGoogleLogin() async {
    final googleSignIn = GoogleSignIn();
    await ref.read(authNotifierProvider.notifier).loginWithGoogle(() async {
      try {
        final account = await googleSignIn.signIn();
        if (account == null) return null; // Aborted
        final auth = await account.authentication;
        return auth.idToken;
      } catch (e) {
        debugPrint("Google Sign In Error: $e");
        return null;
      }
    });
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
          const SnackBar(content: Text('¡Código enviado! Revisa tu WhatsApp o SMS.')),
        );
      }
    }
  }

  Future<void> _verifyCode() async {
    final phone = _phoneController.text.trim();
    final code = _otpController.text.trim();
    if (phone.isEmpty || code.isEmpty) return;

    // The listener in build will handle navigation on success
    await ref
        .read(authNotifierProvider.notifier)
        .verifySmsCode(phone: phone, code: code);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final themeConfig = ref.watch(themeConfigProvider);
    
    final primaryColor = themeConfig.primaryColor;

    // Listen for Auth Success
    ref.listen(authNotifierProvider, (previous, next) {
      if ((previous == null || !previous.isAuthenticated) && next.isAuthenticated) {
         context.go('/dashboard');
      }
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
           content: Text(next.errorMessage!),
           backgroundColor: Colors.red,
         ));
      }
    });

    return AuthWaveBackground(
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo with Glow
                  if (themeConfig.logoUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.5),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          color: Colors.white, // Ensure white background for the logo circle
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0), // Padding inside the white circle
                            child: Image.asset(
                              themeConfig.logoUrl,
                              height: 140, // Reduced slightly to fit inside padding
                              width: 140,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Main Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Verification Title (Centered)
                        if (_isCodeSent)
                          Text(
                            'Verificación',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          )
                        else
                        // Custom Toggle Switch
                        Container(
                          height: 55,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                children: [
                                  AnimatedAlign(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                    alignment: _isLoginMode ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Container(
                                      width: constraints.maxWidth / 2,
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryColor.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() => _isLoginMode = false);
                                            ref.read(authNotifierProvider.notifier).clearError();
                                          },
                                          behavior: HitTestBehavior.opaque,
                                          child: Center(
                                            child: Text(
                                              'Crear Cuenta',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: !_isLoginMode ? Colors.black : Colors.grey.shade600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() => _isLoginMode = true);
                                            ref.read(authNotifierProvider.notifier).clearError();
                                          },
                                          behavior: HitTestBehavior.opaque,
                                          child: Center(
                                            child: Text(
                                              'Iniciar Sesión',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: _isLoginMode ? Colors.black : Colors.grey.shade600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }
                          ),
                        ),
                        
                        const SizedBox(height: 32),

                        // Error Message
                        if (authState.errorMessage != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    authState.errorMessage!,
                                    style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (!_isCodeSent) ...[
                          AnimatedCrossFade(
                            firstChild: Column(
                              children: [
                                TextField(
                                  controller: _nameController,
                                  style: const TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    labelText: 'Nombre Completo',
                                    prefixIcon: Icon(Icons.person_outline, color: themeConfig.secondaryFontColor),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(color: Colors.black),
                                   decoration: InputDecoration(
                                    labelText: 'Correo Electrónico (Opcional)',
                                    prefixIcon: Icon(Icons.alternate_email, color: themeConfig.secondaryFontColor),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                            secondChild: const SizedBox(width: double.infinity),
                            crossFadeState: _isLoginMode ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 300),
                          ),

                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              labelText: 'Número de Teléfono',
                              prefixIcon: Icon(Icons.phone_iphone, color: themeConfig.secondaryFontColor),
                              hintText: '55 1234 5678',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(FontAwesomeIcons.whatsapp, size: 16, color: Colors.green.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Te enviaremos el código por WhatsApp o SMS.',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // OTP Input
                          Text(
                            'Ingresa el código de 6 dígitos enviado a\n${_phoneController.text}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black, fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: '000000',
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(vertical: 20),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isCodeSent = false;
                                _otpController.clear();
                              });
                            },
                            child: const Text('¿Te equivocaste de número? Corregir'),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Main Action Button
                        if (authState.isLoading)
                          const Center(
                            child: CircularProgressIndicator(),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton(
                                onPressed: _isCodeSent ? _verifyCode : _sendCode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeConfig.buttonColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 5,
                                  shadowColor: themeConfig.buttonColor.withOpacity(0.4),
                                ),
                                child: Text(
                                  _isCodeSent ? 'VERIFICAR CÓDIGO' : 'CONTINUAR',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),

                              // Google Sign In Button
                              if (!_isCodeSent) ...[
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.grey.shade300)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text("O", style: TextStyle(color: Colors.grey.shade500)),
                                    ),
                                    Expanded(child: Divider(color: Colors.grey.shade300)),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                OutlinedButton.icon(
                                  onPressed: _handleGoogleLogin,
                                  icon: const Icon(FontAwesomeIcons.google, size: 20, color: Colors.black),
                                  label: const Text("Continuar con Google", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    side: BorderSide(color: Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Back Button (Floating) - Moved to end to be on top
          Positioned(
            top: 16,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => context.go('/welcome'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
