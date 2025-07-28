#!/bin/bash

# Fact Pulse - Development Setup Script
# This script helps set up the necessary configuration files for development

echo "🔧 Setting up Fact Pulse development environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ .env file not found!${NC}"
    echo "Please create a .env file first with your API keys and credentials."
    echo "See FIREBASE_SETUP.md for detailed instructions."
    exit 1
fi

echo -e "${GREEN}✅ Found .env file${NC}"

# Source the .env file to get variables
source .env

# Copy template files if they don't exist
echo -e "${BLUE}📁 Setting up configuration files...${NC}"

# iOS Info.plist
if [ ! -f "ios/Runner/Info.plist" ]; then
    if [ -f "ios/Runner/Info.plist.template" ]; then
        cp ios/Runner/Info.plist.template ios/Runner/Info.plist
        echo -e "${GREEN}✅ Created ios/Runner/Info.plist${NC}"
        
        # Replace placeholder with actual client ID
        if [ ! -z "$GOOGLE_OAUTH_CLIENT_ID_IOS" ]; then
            sed -i.bak "s/YOUR_GOOGLE_OAUTH_CLIENT_ID_IOS/$GOOGLE_OAUTH_CLIENT_ID_IOS/g" ios/Runner/Info.plist
            # Extract client ID part for URL scheme
            CLIENT_ID_PART=$(echo "$GOOGLE_OAUTH_CLIENT_ID_IOS" | cut -d'-' -f1)
            sed -i.bak "s/YOUR_CLIENT_ID/$CLIENT_ID_PART/g" ios/Runner/Info.plist
            rm ios/Runner/Info.plist.bak
            echo -e "${GREEN}  ↳ Updated with OAuth client ID${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Template not found: ios/Runner/Info.plist.template${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  ios/Runner/Info.plist already exists${NC}"
fi

# macOS Info.plist
if [ ! -f "macos/Runner/Info.plist" ]; then
    if [ -f "macos/Runner/Info.plist.template" ]; then
        cp macos/Runner/Info.plist.template macos/Runner/Info.plist
        echo -e "${GREEN}✅ Created macos/Runner/Info.plist${NC}"
        
        # Replace placeholder with actual client ID
        if [ ! -z "$GOOGLE_OAUTH_CLIENT_ID_IOS" ]; then
            sed -i.bak "s/YOUR_GOOGLE_OAUTH_CLIENT_ID_IOS/$GOOGLE_OAUTH_CLIENT_ID_IOS/g" macos/Runner/Info.plist
            # Extract client ID part for URL scheme
            CLIENT_ID_PART=$(echo "$GOOGLE_OAUTH_CLIENT_ID_IOS" | cut -d'-' -f1)
            sed -i.bak "s/YOUR_CLIENT_ID/$CLIENT_ID_PART/g" macos/Runner/Info.plist
            rm macos/Runner/Info.plist.bak
            echo -e "${GREEN}  ↳ Updated with OAuth client ID${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Template not found: macos/Runner/Info.plist.template${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  macos/Runner/Info.plist already exists${NC}"
fi

# Web index.html
if [ ! -f "web/index.html" ]; then
    if [ -f "web/index.html.template" ]; then
        cp web/index.html.template web/index.html
        echo -e "${GREEN}✅ Created web/index.html${NC}"
        
        # Replace placeholder with actual client ID
        if [ ! -z "$GOOGLE_OAUTH_CLIENT_ID_WEB" ]; then
            sed -i.bak "s/YOUR_GOOGLE_OAUTH_CLIENT_ID_WEB/$GOOGLE_OAUTH_CLIENT_ID_WEB/g" web/index.html
            rm web/index.html.bak
            echo -e "${GREEN}  ↳ Updated with web OAuth client ID${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Template not found: web/index.html.template${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  web/index.html already exists${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Setup complete!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Make sure you have the Firebase configuration files:"
echo "   - android/app/google-services.json"
echo "   - ios/Runner/GoogleService-Info.plist"  
echo "   - macos/Runner/GoogleService-Info.plist"
echo ""
echo "2. Run: flutter pub get"
echo "3. Run: flutter run"
echo ""
echo -e "${YELLOW}📖 For detailed setup instructions, see FIREBASE_SETUP.md${NC}" 