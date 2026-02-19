# TODO - Connect Flutter to Express Backend

## Backend Updates
- [x] Update server.js to print full server URL (http://localhost:5000)

## Frontend Updates
- [ ] Add backend URL to constants.dart
- [ ] Create api_backend.dart with real HTTP client
- [ ] Update app to use ApiBackend instead of LocalBackend

## Implementation Steps:
1. ✅ Update ../BeatHub_backend/server.js - print full URL
2. Update lib/core/constants.dart - add BACKEND_URL
3. Create lib/backend/api_backend.dart - HTTP client implementation
4. Update lib/app.dart or main.dart - switch to ApiBackend
