#!/usr/bin/env bash
set -euo pipefail

echo "=== Setting up Smart Inbox AI environment ==="

# Check Homebrew tools
command -v /opt/homebrew/bin/flutter >/dev/null 2>&1 || { echo "Error: Flutter not found"; exit 1; }
command -v /opt/homebrew/bin/uv >/dev/null 2>&1 || { echo "Error: uv not found"; exit 1; }

# Setup Backend venv with uv
echo "Setting up Python backend environment..."
cd backend
/opt/homebrew/bin/uv venv --clear --python /opt/homebrew/opt/python@3.11/bin/python3.11 .venv
/opt/homebrew/bin/uv pip install -e ".[dev]"
cd ..

# Setup Flutter dependencies
echo "Setting up Flutter app dependencies..."
cd app
/opt/homebrew/bin/flutter pub get
cd ..

echo "=== Setup complete! ==="
