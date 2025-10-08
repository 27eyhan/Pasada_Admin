#!/usr/bin/env bash
set -euo pipefail

echo "=== Starting Vercel Install Script ==="
echo "Working directory: $(pwd)"

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
echo "=== Setting up .env file ==="
if [ ! -f assets/.env ]; then
  if [ -f assets/.env.example ]; then
    echo "Copying assets/.env.example to assets/.env"
    cp assets/.env.example assets/.env
  else
    echo "Creating empty assets/.env file"
    mkdir -p assets
    : > assets/.env
  fi
else
  echo "assets/.env already exists"
fi

# Inject Vercel environment variables into assets/.env when available
set_kv() {
  local key="$1"; shift
  local value="${1:-}"
  if [ -n "$value" ]; then
    if grep -q "^${key}=" assets/.env 2>/dev/null; then
      # Use a temporary file for sed to work across all platforms
      sed "s#^${key}=.*#${key}=${value//#/\\#}#" assets/.env > assets/.env.tmp && mv assets/.env.tmp assets/.env
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
set_kv PASADA_WEB_APP_KEY "${PASADA_WEB_APP_KEY:-}"
set_kv AUTH_DOMAIN "${AUTH_DOMAIN:-}"
set_kv WEB_PROJECT_ID "${WEB_PROJECT_ID:-}"
set_kv STORAGE_BUCKET "${STORAGE_BUCKET:-}"
set_kv MESSAGING_SENDER_ID "${MESSAGING_SENDER_ID:-}"
set_kv WEB_APP_ID "${WEB_APP_ID:-}"
set_kv FCM_API_KEY "${FCM_API_KEY:-}"

# Export variables from .env file for the build process
echo "=== Exporting environment variables ==="
if [ -f assets/.env ]; then
  set -a  # automatically export all variables
  source assets/.env || true
  set +a  # stop auto-exporting
fi

# Check if required Firebase environment variables are set
required_vars=("PASADA_WEB_APP_KEY" "AUTH_DOMAIN" "WEB_PROJECT_ID" "STORAGE_BUCKET" "MESSAGING_SENDER_ID" "WEB_APP_ID")

echo "Checking required Firebase variables..."
for var in "${required_vars[@]}"; do
    if [ -z "${!var:-}" ]; then
        echo "Warning: $var is not set in .env file"
    else
        echo "✓ $var is set"
    fi
done

# Create firebase-config.js with actual values
echo "=== Generating Firebase configuration ==="
cat > web/firebase-config.js << EOF
// Firebase configuration for web
// Generated automatically - do not edit manually
const firebaseConfig = {
  apiKey: "${PASADA_WEB_APP_KEY:-}",
  authDomain: "${AUTH_DOMAIN:-}",
  projectId: "${WEB_PROJECT_ID:-}",
  storageBucket: "${STORAGE_BUCKET:-}",
  messagingSenderId: "${MESSAGING_SENDER_ID:-}",
  appId: "${WEB_APP_ID:-}"
};

// Export for use in other files
if (typeof module !== 'undefined' && module.exports) {
  module.exports = firebaseConfig;
} else if (typeof window !== 'undefined') {
  window.firebaseConfig = firebaseConfig;
}
EOF

echo "Firebase configuration injected successfully"
echo "Generated web/firebase-config.js with environment variables"
echo "=== Vercel Install Script Completed Successfully ==="
