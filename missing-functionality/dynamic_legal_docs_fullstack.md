# Task: Dynamic Legal Documents (Terms & Privacy)

## Context
The user wants "Términos y Condiciones" and "Política de Privacidad" to be dynamic, manageable from the Web App (Palantir), and served by the Backend (Yamato) to the Mobile App (Yellow).

## Scope

### 1. Backend (Yamato-Go-Gin-API)
- [ ] **Database**: Ensure `settings` table can store large text values for keys like `legal.terms` and `legal.privacy`.
- [ ] **API Endpoints**:
    - [ ] `GET /legal/terms` (Public or Authenticated?) -> Return terms text/html.
    - [ ] `GET /legal/privacy` -> Return privacy text/html.
    - [ ] `PUT /admin/legal/terms` (Admin only) -> Update terms.
    - [ ] `PUT /admin/legal/privacy` (Admin only) -> Update privacy.
- [ ] **Seeding**: Add default texts in `seeder.go`.

### 2. Web App (Palantir)
- [ ] **Admin UI**:
    - [ ] Add a "Legal" or "Content Management" section in the admin dashboard.
    - [ ] Create editors (WYSIWYG or Markdown) for Terms and Privacy.
    - [ ] Connect to Backend Admin endpoints (`PUT`).

### 3. Mobile App (Yellow)
- [ ] **Repository Layer**:
    - [ ] Add `getTerms()` and `getPrivacyPolicy()` methods to `SettingsRepository` (or `LegalRepository`).
    - [ ] Implement API calls.
- [ ] **UI Implementation**:
    - [ ] Update `PrivacyPolicyScreen` to fetch content asynchronously.
    - [ ] Re-create `TermsScreen` (or equivalent section) to fetch content asynchronously.
    - [ ] Handle loading and error states.
