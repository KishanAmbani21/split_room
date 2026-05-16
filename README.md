# Room Expense Manager

Android-only Flutter app with Firebase Authentication and Firestore user profiles.

## Build

```bash
flutter pub get
flutter run
flutter build apk --debug
```

Firebase uses `android/app/google-services.json` and writes user profiles to `users/{uid}`.
