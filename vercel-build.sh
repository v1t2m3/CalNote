#!/bin/bash

# 1. Tải và cài đặt Flutter SDK nếu chưa có
# Chúng ta sử dụng cache của Vercel (nếu được cấu hình) hoặc tải mới
if [ ! -d "flutter" ]; then
  echo "Downloading Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
else
  echo "Using cached Flutter SDK."
fi

# 2. Đưa lệnh flutter vào biến môi trường PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Kiểm tra môi trường (và tải các dependency cần thiết của Flutter)
echo "Checking Flutter environment..."
flutter doctor -v

# 4. Build dự án Flutter Web
echo "Building Flutter Web..."
flutter build web --release --no-tree-shake-icons
