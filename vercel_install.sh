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


