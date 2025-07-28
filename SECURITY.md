# Security Documentation

This document outlines the security measures implemented in the Fact Pulse application.

## 🔒 Secured Credentials

### Environment Variables (.env)
All sensitive API keys and credentials are stored in environment variables:
- ✅ **Perplexity API Key** - AI fact-checking service
- ✅ **Google OAuth Client IDs** - For Google Sign-in authentication
- ✅ **Firebase Project Configuration** - Project ID and messaging sender ID

### Platform Configuration Files
Sensitive configuration files are **not committed** to version control:
- ✅ `android/app/google-services.json` - Android Firebase config
- ✅ `ios/Runner/GoogleService-Info.plist` - iOS Firebase config  
- ✅ `macos/Runner/GoogleService-Info.plist` - macOS Firebase config
- ✅ `ios/Runner/Info.plist` - iOS OAuth client configuration
- ✅ `macos/Runner/Info.plist` - macOS OAuth client configuration
- ✅ `web/index.html` - Web OAuth client configuration

## 🛡️ Security Best Practices

### API Key Management
1. **Environment Variable Loading**: All API keys loaded from `.env` file at runtime
2. **Cross-platform Compatibility**: Uses Flutter's `rootBundle` for web compatibility
3. **Error Handling**: App throws clear errors if required keys are missing
4. **No Hardcoded Secrets**: All hardcoded credentials removed from source code

### Firebase Security
1. **Client vs Server Keys**: 
   - ✅ Client-safe Firebase API keys remain in `firebase_options.dart`
   - ❌ Sensitive OAuth secrets moved to environment variables
2. **Security Rules**: Firebase access controlled by server-side security rules
3. **Configuration Separation**: Config files with secrets separated from public config

### OAuth Security
1. **Client ID Protection**: Google OAuth client IDs secured in environment variables
2. **Platform-specific Setup**: Each platform has its own OAuth configuration
3. **URL Scheme Security**: Proper URL schemes configured for OAuth callbacks

## 🔧 Developer Setup

### Automated Setup
```bash
./setup_templates.sh
```
This script:
- Copies template files to correct locations
- Injects OAuth client IDs from `.env` file
- Sets up proper URL schemes automatically
- Validates configuration

### Manual Verification
```bash
# Check that sensitive files are not tracked
git status --porcelain | grep -E "(\.env|google-services|GoogleService-Info|Info\.plist|index\.html)$"

# Should return empty (no results)
```

## 📋 Security Checklist

- [x] All API keys moved to environment variables
- [x] Sensitive config files added to `.gitignore`
- [x] Template files created for developers
- [x] Automated setup script provided
- [x] Documentation updated with security practices
- [x] Cross-platform compatibility maintained
- [x] Error handling for missing credentials
- [x] OAuth client IDs properly secured

## ⚠️ Important Notes

1. **Never commit** `.env` files or Firebase config files to version control
2. **Always validate** that sensitive files are in `.gitignore` before committing
3. **Use the setup script** (`./setup_templates.sh`) for consistent environment setup
4. **Keep credentials private** - never share API keys in public channels
5. **Rotate credentials** if they may have been compromised

## 🔍 Security Audit

Last security review: $(date)
- All hardcoded credentials removed ✅
- Environment variable system implemented ✅  
- Cross-platform compatibility verified ✅
- Developer documentation complete ✅

---

For setup instructions, see [FIREBASE_SETUP.md](FIREBASE_SETUP.md) 