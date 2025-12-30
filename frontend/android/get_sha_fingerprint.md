# How to Get SHA-1 and SHA-256 Fingerprints for Firebase

## For Debug Build (Development)

### Windows (PowerShell):
```powershell
cd android
.\gradlew signingReport
```

### Mac/Linux:
```bash
cd android
./gradlew signingReport
```

Look for the SHA-1 and SHA-256 values in the output under `Variant: debug`

## Alternative Method (Using Keytool)

### Windows:
```cmd
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

### Mac/Linux:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

## Add to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **budbull-app**
3. Go to **Project Settings** (gear icon)
4. Scroll down to **Your apps** section
5. Click on your Android app
6. Click **Add fingerprint**
7. Add both SHA-1 and SHA-256 values
8. Download the updated `google-services.json` and replace the one in `frontend/android/app/`

## Important Notes

- You need to add SHA fingerprints for both **debug** and **release** builds
- After adding fingerprints, wait a few minutes for Firebase to update
- You may need to rebuild the app after updating `google-services.json`

