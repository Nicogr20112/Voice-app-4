# 🎙️ Voz — Word Tracker

App Android que escucha solo tu voz, cuenta las palabras que dices al día y genera resúmenes. Todo guardado localmente.

## Características
- 🎤 Reconocimiento de voz continuo en background
- ▶/⏹ Botón para activar/pausar el registro en cualquier momento
- 📊 Contador de palabras en tiempo real
- 💬 Top palabras más usadas del día
- 📝 Resumen generado al instante (sin internet)
- 📅 Historial de días anteriores
- 💾 Todo guardado en SQLite local, sin cloud

## Requisitos
- Flutter SDK ≥ 3.0.0 → https://flutter.dev/docs/get-started/install
- Android SDK (Android Studio o solo el SDK)
- Java 11+
- Android 8.0+ en el móvil (API 26+)

## Compilar el APK

```bash
# 1. Entra al directorio
cd voz_app

# 2. Instala dependencias
flutter pub get

# 3. Compila el APK
flutter build apk --release

# 4. El APK estará en:
# build/app/outputs/flutter-apk/app-release.apk
```

O simplemente ejecuta:
```bash
chmod +x build_apk.sh && ./build_apk.sh
```

## Instalar en el móvil

**Opción A — USB (adb):**
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Opción B — Manual:**
Copia el APK al móvil y ábrelo (necesitas activar "Fuentes desconocidas" en Ajustes → Seguridad).

## Permisos que pide
- `RECORD_AUDIO` — para escuchar tu voz
- `POST_NOTIFICATIONS` — para el indicador de servicio en background
- `FOREGROUND_SERVICE` — para seguir escuchando con la app minimizada

## Cómo funciona
1. Al abrir la app, pulsa el badge rojo para activar la escucha
2. La app usa `speech_to_text` para transcribir en tiempo real
3. Cada fragmento de voz se guarda en SQLite con timestamp
4. Pulsa "generar resumen del día" en cualquier momento
5. Ve al historial para ver días anteriores
