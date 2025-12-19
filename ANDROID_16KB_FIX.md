# Android 16 KB Page Size Support - Fix Anleitung

## Problem
Google Play Store meldet: "Deine App unterstützt keine Speicherseiten mit 16 KB"

## Ursache
Ab 1. November 2025 müssen alle Apps für Android 15+ 16 KB Speicherseiten unterstützen. Die native Bibliotheken müssen mit NDK r28 oder höher kompiliert werden.

## Lösung - NDK r28 installieren

### Schritt 1: NDK r28 installieren

**Option A: Über Android Studio**
1. Öffne Android Studio
2. Gehe zu: Tools → SDK Manager
3. Wähle den Tab "SDK Tools"
4. Aktiviere "Show Package Details"
5. Suche nach "NDK (Side by side)"
6. Installiere Version 28.0.12674087 oder höher
7. Klicke auf "Apply" und warte auf die Installation

**Option B: Über Command Line**
```bash
# SDK Manager Pfad finden
export ANDROID_HOME=$HOME/Library/Android/sdk

# NDK r28 installieren
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "ndk;28.0.12674087"
```

### Schritt 2: NDK Version in build.gradle.kts aktualisieren

Die Datei `android/app/build.gradle.kts` wurde bereits aktualisiert:
```kotlin
ndkVersion = "28.0.12674087"
```

### Schritt 3: App neu bauen

```bash
flutter clean
flutter build appbundle --release
```

## Bereits durchgeführte Konfigurationen

✅ **AndroidManifest.xml:**
- `extractNativeLibs="false"` gesetzt
- `PROPERTY_NATIVE_LIBRARY_PAGE_SIZE` Meta-Tag mit Wert 16384

✅ **build.gradle.kts:**
- NDK Version auf r28 gesetzt (muss installiert werden)
- Packaging-Konfiguration für 16 KB angepasst
- Bundle-Konfiguration hinzugefügt

✅ **gradle.properties:**
- `android.bundle.enableUncompressedNativeLibs=true` gesetzt

## Wichtige Hinweise

1. **NDK r28 ist zwingend erforderlich** - r27 reicht nicht aus
2. Nach der NDK Installation muss die App neu gebaut werden
3. Alle nativen Bibliotheken werden mit r28 neu kompiliert
4. Die Flutter Engine und Plugins müssen ebenfalls mit r28 kompiliert werden

## Testen

Nach dem Build kannst du die App testen:
```bash
# Prüfe die Seitengröße auf einem Gerät
adb shell getconf PAGE_SIZE
# Sollte 16384 (16 KB) zurückgeben
```

## Weitere Informationen

- [Google's 16 KB Page Size Guide](https://developer.android.com/guide/practices/page-sizes)
- Flutter Issue: Native libraries müssen mit NDK r28+ kompiliert werden

