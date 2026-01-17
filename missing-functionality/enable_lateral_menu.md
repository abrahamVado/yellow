# Task: Enable Lateral Menu Functionality (Yellow App)

## Context
The lateral menu (`AppDrawer`) in the `yellow` app has placeholder items for "Editar Perfil" and "Configuraciones" that currently show a "Próximamente..." SnackBar. The "Métodos de Pago" and "Cerrar Sesión" items are wired but should be verified.

## Requirements

### 1. "Editar Perfil" (Edit Profile)
- [x] Create or identify the "Edit Profile" screen. (Check `features/account` or similar, or create it).
- [x] Implement navigation to this screen in the `onTap` callback.
- [x] Ensure user data (name, email/phone) can be updated.

### 2. "Configuraciones" (Settings)
- [x] Create or identify the "Settings" screen.
- [x] Implement navigation to this screen.
- [x] Add basic settings options (e.g., Notification preferences, Language, Theme toggle if applicable).

### 3. Verify Existing Items
- [x] **Métodos de Pago**: Verify navigation to `/dashboard/add-card` works and the screen exists.
- [x] **Cerrar Sesión**: Verify the logout logic clears tokens and redirects to `/welcome`.

### 4. UI Polish
- [x] Ensure the Drawer closes (`Navigator.pop(context)`) before navigating to the new screens to prevent it from remaining open on back navigation.
