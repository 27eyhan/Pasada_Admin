# Pasada Admin Application

A Flutter-based administrative dashboard for managing transportation services, built with Supabase backend integration and real-time connectivity features.

## Overview

This application provides comprehensive fleet management capabilities including driver management, route optimization, analytics, and real-time monitoring. The system supports multi-platform deployment (web, mobile, desktop) with offline capabilities and session management.

## Key Features

- **Fleet Management**: Real-time vehicle tracking, route management, and driver assignment
- **Analytics Dashboard**: Performance metrics, booking frequency analysis, and traffic insights
- **Driver Management**: Driver profiles, activity logs, and review systems
- **AI Integration**: Gemini AI-powered chat assistant for administrative queries
- **Real-time Connectivity**: Live updates with offline fallback capabilities
- **Session Security**: Configurable session timeouts and authentication guards

## Technical Stack

- **Framework**: Flutter 3.5.0+
- **Backend**: Supabase (PostgreSQL, Auth, Realtime)
- **Maps**: Google Maps Flutter with web support
- **State Management**: Provider pattern with GetX
- **Database**: SQLite for offline storage
- **Authentication**: Supabase Auth with PKCE flow
- **AI Services**: Google Gemini integration

## Architecture

```
lib/
├── config/          # Theme and configuration
├── services/        # Business logic and API services
├── screen/          # UI components and pages
├── models/          # Data models
├── widgets/         # Reusable UI components
└── maps/           # Map integration utilities
```

## Core Services

- **AuthService**: Session management and authentication
- **ConnectivityService**: Network status monitoring
- **RouteTrafficService**: Real-time traffic data
- **GeminiAIService**: AI chat functionality
- **AnalyticsService**: Performance tracking
- **DatabaseSummaryService**: Data aggregation

## Setup

1. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

2. Configure environment variables in `assets/.env`:
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

3. Run the application:
   ```bash
   flutter run
   ```

## Platform Support

- Web (with Google Maps integration)
- Android
- iOS
- Windows
- macOS
- Linux

## Dependencies

Key dependencies include Supabase Flutter, Google Maps, connectivity monitoring, AI services, and comprehensive state management solutions.