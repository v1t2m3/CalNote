#!/bin/bash

# 1. Cài đặt các thư viện cần thiết (nếu có trên Linux)
echo "Updating packages..."
apt-get update -y && apt-get install -y curl git unzip

# 2. Clone Flutter SDK (chọn phiên bản ổn định, ví dụ stable)
echo "Downloading Flutter SDK..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# 3. Đưa lệnh flutter vào biến môi trường PATH của Vercel
export PATH="$PATH:`pwd`/flutter/bin"

# 4. Chấp nhận các điều khoản của Flutter Doctor
flutter doctor --android-licenses || true

# 5. Build dự án Flutter Web
echo "Building Flutter Web..."
flutter build web --release
