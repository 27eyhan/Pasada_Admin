#!/usr/bin/env bash
set -euo pipefail

# Ensure Flutter (stable) is available
if [ -d flutter ]; then
  (
    cd flutter
    git fetch origin stable
    git checkout stable
    git pull
  )
else
  git clone -b stable https://github.com/flutter/flutter.git
fi

# Prepare Flutter for web builds
flutter/bin/flutter config --enable-web
flutter/bin/flutter precache --web
flutter/bin/flutter --version

# Install Dart/Flutter dependencies
flutter/bin/flutter pub get

# Ensure an env file exists for Flutter assets resolution
if [ ! -f assets/.env ]; then
  if [ -f assets/.env.example ]; then
    cp assets/.env.example assets/.env
  else
    mkdir -p assets
    : > assets/.env
  fi
fi

# Inject Vercel environment variables into assets/.env when available
set_kv() {
  local key="$1"; shift
  local value="${1:-}"
  if [ -n "$value" ]; then
    if grep -q "^${key}=" assets/.env; then
      sed -i "s#^${key}=.*#${key}=${value//#/\\#}#" assets/.env
    else
      printf "%s=%s\n" "$key" "$value" >> assets/.env
    fi
  fi
}

set_kv SUPABASE_URL "${SUPABASE_URL:-}"
set_kv SUPABASE_ANON_KEY "${SUPABASE_ANON_KEY:-}"
set_kv GOOGLE_MAPS_API_KEY "${GOOGLE_MAPS_API_KEY:-}"
set_kv API_URL "${API_URL:-}"
set_kv WEATHER_API_KEY "${WEATHER_API_KEY:-}"
set_kv SUPABASE_SERVICE_ROLE_KEY "${SUPABASE_SERVICE_ROLE_KEY:-}"
set_kv RESEND_API_KEY "${RESEND_API_KEY:-}"
set_kv ANALYTICS_API_URL "${ANALYTICS_API_URL:-}"
set_kv GEMINI_API "${GEMINI_API:-}"
set_kv QUESTDB_HTTP "${QUESTDB_HTTP:-}"
set_kv QUESTDB_ILP "${QUESTDB_ILP:-}"
set_kv IOS_MACOS_FIREBASE_KEY "${IOS_MACOS_FIREBASE_KEY:-}"
set_kv ANDROID_FIREBASE_KEY "${ANDROID_FIREBASE_KEY:-}"
set_kv WINDOWS_WEB_FIREBASE_KEY "${WINDOWS_WEB_FIREBASE_KEY:-}"
set_kv ENCRYPTION_MASTER_KEY_B64 "${ENCRYPTION_MASTER_KEY_B64:-}"
set_kv CLOUDFLARE_SITE_KEY "${CLOUDFLARE_SITE_KEY:-}"
set_kv CLOUDFLARE_SECRET_KEY "${CLOUDFLARE_SECRET_KEY:-}"
set_kv ADMIN_SESSIONS_TABLE "${ADMIN_SESSIONS_TABLE:-}"
set_kv adminSessionsTable "${adminSessionsTable:-}"


