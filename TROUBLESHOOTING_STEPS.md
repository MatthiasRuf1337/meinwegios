# Xcode Cloud Troubleshooting - Schritt für Schritt

## Status Check

- [ ] Schritt 1: Aktuellen vereinfachten Build getestet
- [ ] Schritt 2A: Build erfolgreich (FERTIG!)
- [ ] Schritt 2B: Script deaktiviert und neuen Build gestartet

## Falls weiterhin Probleme:

### Option 3: Xcode Cloud Workflow manuell anpassen

1. **Xcode öffnen**
2. **Report Navigator** (⌘9) → **Cloud**
3. **Workflow bearbeiten**
4. **Pre-Actions hinzufügen:**
   ```bash
   cd ios && pod install
   ```

### Option 4: Lokales Archive für manuellen Upload

1. **Terminal:**

   ```bash
   cd /Users/matthias/local/meinweg
   flutter build ios --release
   ```

2. **Xcode öffnen:**

   ```bash
   open ios/Runner.xcworkspace
   ```

3. **In Xcode:**
   - **Product** → **Archive**
   - **Distribute App** → **App Store Connect**

### Option 5: Komplett ohne Xcode Cloud

- **Lokale Builds** → **Manueller Upload**
- **GitHub nur für Code-Verwaltung**
- **Xcode Cloud deaktivieren**

## Debugging Informationen

Bei Problemen diese Informationen sammeln:

- [ ] Xcode Cloud Build-Logs
- [ ] Fehlercode (exit code)
- [ ] Konkrete Fehlermeldung
- [ ] Build-Umgebung (iOS Version, Xcode Version)
