#!/bin/bash

# 1. Tải Flutter SDK
if [ ! -d "flutter" ]; then
  echo "Downloading Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# 2. PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Build Web - Thêm các flag để bỏ qua check lỗi Wasm và Icons
echo "Building Flutter Web..."
flutter pub get
flutter build web --release --no-wasm-dry-run --no-tree-shake-icons
