# Task: Delete "Continuar con Google" Button in Yellow App

## Context
The user wants to remove the "Continuar con Google" button from the `yellow` app. The button is located in `lib/features/auth/presentation/screens/login_screen.dart` at line 432.

## Requirements
- [x] **Remove UI Element**: Delete the `OutlinedButton.icon` widget labeled "Continuar con Google" in `LoginScreen`.
    - Location: `c:\workspace\20k\yellow\lib\features\auth\presentation\screens\login_screen.dart:432`
- [x] **Remove Logic (Optional)**:
    - Check usage of `_handleGoogleLogin` and remove it if no longer needed.
    - Check usage of `loginWithGoogle` in `AuthNotifier` and `AuthRepository`.
    - If Google Sign-In is completely deprecated for this app, remove the `google_sign_in` dependency from `pubspec.yaml`.
- [ ] **Verify**: Ensure the app compiles and runs without the button.
