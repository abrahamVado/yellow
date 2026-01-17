# Task: Implement Settings Features (Yellow App)

## Context
The "Configuraciones" screen currently has non-functional UI elements. The user wants to fully implement these features.

## Requirements

### 1. Notifications (Notificaciones)
- [ ] **Permissions**: Check and request Notification permissions when the toggle is turned on.
- [ ] **Persistence**: Save the user's preference (on/off) using `SharedPreferences` or a local database.
- [ ] **Logic**: If disabled, prevent displaying local notifications (or unregister FCM if applicable).

### 2. Language (Idioma)
- [ ] **Localization Setup**: Ensure the app is set up for localization (e.g., `flutter_localizations`, `intl`).
- [ ] **Language Selection**: Create a dialog or bottom sheet to select between "Español" and "English".
- [ ] **Persistence**: Save selected language.
- [ ] **Application**: Apply the selected locale to the `MaterialApp` via a Riverpod provider.

### 3. Terms & Conditions (Términos y Condiciones)
- [ ] **Content**: Obtain the "Terms and Conditions" URL or text content. (Use a placeholder URL like `https://example.com/terms` if actual one is unknown).
- [ ] **Navigation**: Navigate to a `WebView` screen or a specific Content Screen to display the terms.

### 4. About (Acerca de) - *Located in Drawer, but relevant*
- [ ] Consider adding an "About" section in Settings or verify the one in the Drawer is sufficient. (Currently just shows a dialog).
