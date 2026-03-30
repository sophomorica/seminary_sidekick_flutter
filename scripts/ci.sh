#!/bin/bash

# Seminary Sidekick - Local CI Script
# This script runs the same checks as GitHub Actions CI

set -e

echo "🏃 Running local CI checks..."

echo "📦 Installing dependencies..."
flutter pub get

echo "🔍 Running Flutter analyze..."
flutter analyze

echo "🧪 Running Flutter tests..."
flutter test --coverage

echo "✅ All checks passed!"
echo ""
echo "Coverage report generated in coverage/lcov.info"
echo "View HTML report: open coverage/html/index.html"