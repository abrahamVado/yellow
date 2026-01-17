# Task: Enable Edit Profile (Full Stack)

## Context
The user wants to fully enable the "Edit Profile" functionality. This requires changes in the Yellow app, the Backend (Yamato), and specific "Palantir" zone configurations.

## Scope

### 1. Backend (Yamato-Go-Gin-API)
- [ ] **Endpoint Analysis**: Verify if `PUT /auth/me` or `/user/profile` exists.
- [ ] **Implementation**:
    - [ ] Create/Update endpoint to accept profile updates (First Name, Last Name, Email, maybe Phone).
    - [ ] Add validation logic.
    - [ ] Verify database update logic.
- [ ] **Response**: Ensure updated user object is returned.

### 2. Frontend (Yellow App)
- [ ] **UI Implementation** (`EditProfileScreen`):
    - [ ] Create form with existing user data (pre-filled).
    - [ ] Add input validation.
    - [ ] Add "Save" button with loading state.
- [ ] **Logic (`AuthNotifier` / `AuthRepository`)**:
    - [ ] Add `updateProfile(Map<String, dynamic> data)` to Repository.
    - [ ] Implement API call in `AuthRemoteDataSource`.
    - [ ] Update local user state in `AuthNotifier` upon success.

### 3. Palantir (Configuration/Zones)
- [ ] **Zone Configuration**:
    - [ ] Analyze Palantir configuration files to identify "zone" settings related to user profiles.
    - [ ] Ensure "Edit Profile" capability is enabled for all zones.
    - [ ] Apply necessary config changes to propagate to all environments.
