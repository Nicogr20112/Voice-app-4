#!/bin/bash
# ════════════════════════════════════════════
#  VOZ APP — Build Script
#  Requiere: Flutter SDK instalado y en PATH
# ════════════════════════════════════════════

set -e

echo "🎙️  Construyendo Voz App..."

# Comprobar Flutter
if ! command -v flutter &> /dev/null; then
  echo "❌ Flutter no encontrado. Instálalo desde https://flutter.dev/docs/get-started/install"
  exit 1
fi

echo "✓ Flutter encontrado: $(flutter --version | head -1)"

# Instalar dependencias
echo ""
echo "📦 Instalando dependencias..."
flutter pub get

# Compilar APK release
echo ""
echo "🔨 Compilando APK..."
flutter build apk --release

echo ""
echo "✅ APK compilado exitosamente!"
echo "📍 Ubicación: build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "Para instalar directamente en tu Android (con USB):"
echo "  adb install build/app/outputs/flutter-apk/app-release.apk"
