# Firebase Configuration Setup

This project uses Firebase for authentication and Firestore. The Firebase configuration files contain sensitive API keys and project credentials, so they are not included in the repository.

## Required Files

You need to obtain these files from the Firebase Console and set up OAuth credentials:

### Firebase Configuration Files
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `macos/Runner/GoogleService-Info.plist`

### Platform-Specific Configuration Files (OAuth Client IDs)
- `ios/Runner/Info.plist` (copy from `Info.plist.template` and update)
- `macos/Runner/Info.plist` (copy from `Info.plist.template` and update)  
- `web/index.html` (copy from `index.html.template` and update)

## How to Get These Files

### Firebase Configuration Files

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create a new one)
3. Go to Project Settings (gear icon)
4. In the "Your apps" section, download the config files:
   - For Android: Click on the Android app → Download `google-services.json`
   - For iOS: Click on the iOS app → Download `GoogleService-Info.plist`
   - For macOS: Click on the macOS app → Download `GoogleService-Info.plist`

### Google OAuth Client IDs

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Go to "APIs & Services" → "Credentials"
4. Create OAuth 2.0 Client IDs for:
   - **iOS application** (for iOS/macOS)
   - **Web application** (for web)
   - **Android application** (if not auto-created)

### Setting Up Platform Files

After getting your OAuth client IDs:

```bash
# Copy template files
cp ios/Runner/Info.plist.template ios/Runner/Info.plist
cp macos/Runner/Info.plist.template macos/Runner/Info.plist  
cp web/index.html.template web/index.html

# Update your .env file with the client IDs
# Then the templates will reference these environment variables
```

## File Placement

Place the downloaded files in the following locations:

```
android/app/google-services.json
ios/Runner/GoogleService-Info.plist  
macos/Runner/GoogleService-Info.plist
```

## Security Note ⚠️

- These files contain sensitive API keys and credentials
- They are already added to `.gitignore` and should NEVER be committed to version control
- Each developer needs their own copy from the Firebase project

## Firebase Project Setup

Make sure your Firebase project has the following enabled:
- Authentication (Google, Email/Password)
- Firestore Database
- Storage (for image uploads)

## Environment Variables

Create a `.env` file with all required credentials:
```bash
# Perplexity API Key
PERPLEXITY_API_KEY=your_perplexity_api_key_here

# Google OAuth Client IDs (get from Google Cloud Console)
GOOGLE_OAUTH_CLIENT_ID_IOS=your_ios_client_id.apps.googleusercontent.com
GOOGLE_OAUTH_CLIENT_ID_ANDROID=your_android_client_id.apps.googleusercontent.com
GOOGLE_OAUTH_CLIENT_ID_WEB=your_web_client_id.apps.googleusercontent.com

# Firebase Project Info
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
```

## Quick Setup Script ⚡

After setting up your `.env` file with the correct credentials, run:

```bash
./setup_templates.sh
```

This script will:
- ✅ Copy template files to the correct locations
- ✅ Automatically inject your OAuth client IDs from `.env`  
- ✅ Set up the proper URL schemes
- ✅ Validate that everything is configured correctly

## Manual Setup (Alternative)

If you prefer to set up manually:

```bash
# 1. Copy template files
cp ios/Runner/Info.plist.template ios/Runner/Info.plist
cp macos/Runner/Info.plist.template macos/Runner/Info.plist
cp web/index.html.template web/index.html

# 2. Edit each file and replace:
#    - YOUR_GOOGLE_OAUTH_CLIENT_ID_IOS → your iOS client ID
#    - YOUR_GOOGLE_OAUTH_CLIENT_ID_WEB → your web client ID  
#    - YOUR_CLIENT_ID → first part of your client ID (before the -)
``` 