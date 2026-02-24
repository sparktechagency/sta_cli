#!/bin/bash
set -e

echo "📦 Installing STA CLI..."

# Install dependencies
dart pub get

# Compile to native binary
dart compile exe bin/main.dart -o sta

# Move to PATH
if [ -w /usr/local/bin ]; then
  mv sta /usr/local/bin/sta
  echo "✔ Installed to /usr/local/bin/sta"
else
  sudo mv sta /usr/local/bin/sta
  echo "✔ Installed to /usr/local/bin/sta"
fi

echo ""
echo "✅ Done! Try: sta --help"
