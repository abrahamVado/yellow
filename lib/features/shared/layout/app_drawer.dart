import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../application/auth/auth_providers.dart';
import '../../../../app/theme/theme_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeConfig = ref.watch(themeConfigProvider);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isAuthenticated = authState.isAuthenticated;
    
    // Force refresh profile if authenticated but user is null (fix for "Hola, Viajero")
    if (isAuthenticated && user == null) {
      // Defer state update to next frame to avoid build error
      Future.microtask(() => ref.read(authNotifierProvider.notifier).fetchProfile());
    }

    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // 1. Modern Header
          _buildHeader(context, themeConfig, user, isAuthenticated),
          
          const SizedBox(height: 20),
          
          // 2. Menu Items (Clean & Flat)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                if (isAuthenticated) ...[
                  /* 
                     NOTE: Main navigation is in Dashboard. 
                     Sidebar is for Account/Settings/Support.
                  */
                  
                  // Example: Profile Edit (Placeholder for future)
                  _buildModernMenuItem(
                    context,
                    icon: FontAwesomeIcons.userPen,
                    title: 'Editar Perfil',
                    onTap: () {
                      // TODO: Navigate to Edit Profile
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Próximamente...')));
                    },
                  ),

                   // Example: Settings
                  _buildModernMenuItem(
                    context,
                    icon: FontAwesomeIcons.gear,
                    title: 'Configuraciones',
                    onTap: () {
                       Navigator.pop(context);
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Próximamente...')));
                    },
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),

                  _buildModernMenuItem(
                    context,
                    icon: FontAwesomeIcons.arrowRightFromBracket,
                    title: 'Cerrar Sesión',
                    onTap: () async {
                      await ref.read(authNotifierProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/welcome');
                      }
                    },
                    isDestructive: true,
                  ),
                ] else ...[
                  _buildModernMenuItem(
                    context,
                    icon: FontAwesomeIcons.rightToBracket,
                    title: 'Iniciar Sesión',
                    onTap: () => context.go('/login'),
                    color: themeConfig.primaryColor,
                  ),
                ],
              ],
            ),
          ),
          
          // 3. Subtle Footer (About & Version)
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic themeConfig, dynamic user, bool isAuthenticated) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 40, left: 24, right: 24),
      decoration: BoxDecoration(
        color: Colors.white,
       // Subtle gradient or pattern could go here, but white is cleaner
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with Status Indicator
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: themeConfig.primaryColor, width: 2),
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey.shade100,
                  child: Text(
                    isAuthenticated && user != null ? user.firstName[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: themeConfig.primaryColor),
                  ),
                ),
              ),
              if (isAuthenticated)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Name & Email
          Text(
            isAuthenticated && user != null 
                ? '${user.firstName} ${user.lastName}' 
                : 'Bienvenido',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isAuthenticated && user != null 
                ? (user.email.isNotEmpty ? user.email : user.phoneNumber) 
                : 'Invitado',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernMenuItem(BuildContext context, {
    required IconData icon, 
    required String title, 
    required VoidCallback onTap, 
    bool isDestructive = false,
    Color? color,
  }) {
    final finalColor = isDestructive ? Colors.red.shade400 : (color ?? Colors.black87);
    
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: finalColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: finalColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: finalColor,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade300),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Icon(Icons.info_outline, size: 16, color: Colors.grey.shade400),
               const SizedBox(width: 8),
               TextButton(
                 onPressed: () {
                   // Show basic about dialog
                   showAboutDialog(
                     context: context,
                     applicationName: 'Mathey Pasajero',
                     applicationVersion: '1.0.0',
                     applicationIcon: const Icon(Icons.local_taxi),
                     children: [const Text('Tu viaje, tu seguridad.')],
                   );
                 },
                 child: Text(
                   'Acerca de',
                   style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                 ),
               )
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'v1.0.0',
            style: TextStyle(color: Colors.grey.shade300, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
