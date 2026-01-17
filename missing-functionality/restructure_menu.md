# Task: Restructure Lateral Menu (Yellow App)

## Context
The user wants a specific list of items in the lateral menu:
1.  **Mi Perfil** (Review info)
2.  **Métodos de Pago** (Existing)
3.  **Política de Privacidad** (New text view)
4.  **Borrar Mi Cuenta** (Delete account functionality)
5.  **Cerrar Sesión** (Logout)

## Requirements

### 1. Privacy Policy
- [ ] Create `PrivacyPolicyScreen` with static text.
- [ ] Add route `/dashboard/privacy-policy`.

### 2. Delete Account Refactor
- [ ] Rename `SettingsScreen` to `DeleteAccountScreen` (file and class) to match its new single purpose.
- [ ] Update route from `/dashboard/settings` to `/dashboard/delete-account`.

### 3. App Drawer Updates
- [ ] Update items to match the exact list above.
- [ ] "Mi Perfil" -> Navigates to existing `EditProfileScreen`.
- [ ] "Métodos de Pago" -> Keep existing.
- [ ] "Política de Privacidad" -> Navigates to new screen.
- [ ] "Borrar Mi Cuenta" -> Navigates to `DeleteAccountScreen`.
- [ ] "Cerrar Sesión" -> Keep existing logic.
