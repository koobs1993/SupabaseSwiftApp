# SupabaseSwiftApp

A powerful iOS application built with SwiftUI and Supabase.

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/SupabaseSwiftApp.git
```

2. Create environment files
```bash
cp .env.example .env.development
cp .env.example .env.production
```

3. Update environment variables in `.env.development` and `.env.production`:
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

4. Open `SupabaseSwiftApp.xcodeproj` in Xcode

5. Build and run the project

## Deployment Checklist

1. Update version and build numbers in Info.plist
2. Verify all environment variables are set correctly
3. Test all features in Production environment
4. Generate App Store screenshots
5. Update App Store metadata
6. Archive and upload to App Store Connect

## Features

- User Authentication
- Course Management
- Psychological Tests
- Weekly Columns
- Chat System
- Push Notifications
- In-App Purchases
- Profile Management

## Architecture

- MVVM Architecture
- SwiftUI for UI
- Supabase for Backend
- Combine for Reactive Programming

## Security

- Secure environment variable handling
- Proper API key management
- Data encryption at rest
- Secure network communication

## Support

For support, email support@yourdomain.com