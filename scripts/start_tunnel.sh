#!/usr/bin/env bash
# =============================================================================
# Start ngrok tunnel to expose backend (port 8000) for real device testing
# =============================================================================

set -e

PORT=${1:-8000}

if ! command -v ngrok &> /dev/null; then
    echo "❌ ngrok chưa được cài đặt. Vui lòng cài đặt qua: brew install ngrok"
    exit 1
fi

echo "================================================================="
echo " 🌐 Khởi động ngrok tunnel cho backend vnverse tại cổng ${PORT}"
echo "================================================================="
echo "Sau khi ngrok khởi động, hãy copy đường dẫn HTTPS (ví dụ: https://xxxx.ngrok-free.app)"
echo "và dán vào mục 'Cấu hình máy chủ Backend' trên app di động."
echo "================================================================="

ngrok http ${PORT}
