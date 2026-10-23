#!/usr/bin/env bash
set -euo pipefail

echo "=========================================="
echo " Running All Lints & Tests"
echo "=========================================="

echo "[1/4] Flutter Analyze..."
cd app
/opt/homebrew/bin/flutter analyze
cd ..

echo "[2/4] Flutter Tests..."
cd app
/opt/homebrew/bin/flutter test
cd ..

echo "[3/4] Backend Lint (Ruff)..."
cd backend
source .venv/bin/activate
ruff check .
cd ..

echo "[4/4] Backend Tests (Pytest)..."
cd backend
source .venv/bin/activate
pytest -v
cd ..

echo "=========================================="
echo " All checks passed successfully! "
echo "=========================================="
