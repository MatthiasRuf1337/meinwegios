# Hintergrund-Tracking Problem - Lösung

## Problem

Die App hat das Problem, dass beim Wechsel in den Hintergrund (z.B. bei Telefonaten, anderen Apps) keine GPS-Punkte mehr erstellt werden und das Tracking stoppt.

## Ursache

Der ursprüngliche GPS-Stream war nicht richtig für Hintergrund-Tracking konfiguriert. Insbesondere fehlten wichtige Einstellungen wie:

- `pauseLocationUpdatesAutomatically: false` (iOS)
- `enableWakeLock: true` (Android)
- Optimierte `distanceFilter` und `intervalDuration` Werte

## Lösung

### 1. Verbesserte GPS-Stream-Konfiguration

```dart
// iOS
AppleSettings(
  accuracy: LocationAccuracy.best,
  activityType: ActivityType.fitness,
  distanceFilter: 2, // Reduziert für bessere Genauigkeit
  pauseLocationUpdatesAutomatically: false, // Wichtig für Hintergrund
  showBackgroundLocationIndicator: true, // Zeigt Hintergrund-Tracking an
)

// Android
AndroidSettings(
  accuracy: LocationAccuracy.best,
  distanceFilter: 2, // Reduziert für bessere Genauigkeit
  forceLocationManager: false,
  intervalDuration: const Duration(seconds: 3), // Häufigere Updates
  foregroundNotificationConfig: const ForegroundNotificationConfig(
    notificationText: "Mein Weg verfolgt Ihre Etappe im Hintergrund",
    notificationTitle: "GPS-Tracking aktiv",
    enableWakeLock: true, // Verhindert, dass das Gerät schläft
  ),
)
```

### 2. App-Lifecycle-Behandlung

- **App geht in Hintergrund**: GPS-Stream läuft weiter mit optimierten Einstellungen
- **App kommt in Vordergrund**: GPS-Stream wird überwacht und bei Bedarf fortgesetzt
- **Zusätzliche Validierung**: Im Hintergrund werden strengere GPS-Qualitätsfilter angewendet

### 3. Verbesserte GPS-Punkt-Validierung

- **Vordergrund**: Genauigkeit bis 30m akzeptiert
- **Hintergrund**: Genauigkeit bis 20m für bessere Qualität
- **Zusätzliche Filter**: Null-Koordinaten, unrealistische Sprünge werden verworfen

### 4. Android-Manifest-Konfiguration

Alle notwendigen Berechtigungen sind bereits konfiguriert:

```xml
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

## Wichtige Einstellungen

### distanceFilter

- **Vorher**: 3-5 Meter
- **Jetzt**: 2 Meter
- **Effekt**: Bessere Genauigkeit, mehr GPS-Punkte

### intervalDuration

- **Vorher**: 5-10 Sekunden
- **Jetzt**: 3 Sekunden
- **Effekt**: Häufigere Updates, weniger GPS-Lücken

### pauseLocationUpdatesAutomatically

- **iOS**: `false` - Verhindert automatisches Pausieren
- **Android**: `enableWakeLock: true` - Verhindert, dass das Gerät schläft

## Testing

### Vordergrund-Tracking

1. App öffnen und Etappe starten
2. GPS-Punkte sollten alle 3 Sekunden bei Bewegung > 2m erstellt werden
3. Genauigkeit sollte ≤ 30m sein

### Hintergrund-Tracking

1. App starten und Etappe aktivieren
2. App in Hintergrund legen (z.B. Home-Button drücken)
3. GPS-Tracking sollte weiterlaufen (Notification sichtbar)
4. Nach 1-2 Minuten App wieder öffnen
5. Neue GPS-Punkte sollten sichtbar sein

### Debugging

- Logs zeigen "GPS-Tracking läuft im Hintergrund weiter..."
- Logs zeigen "GPS-Punkt im Hintergrund hinzugefügt: Xm, Total: Ym"
- Bei Problemen: Logs zeigen "GPS-Stream war pausiert - setze fort..."

## Bekannte Einschränkungen

### iOS

- `distanceFilter` kann nicht dynamisch geändert werden
- Hintergrund-Tracking funktioniert nur mit "Always" Permission
- System kann GPS-Updates bei starker Batterieoptimierung reduzieren

### Android

- `enableWakeLock` kann Batterieverbrauch erhöhen
- System kann GPS-Updates bei starker Batterieoptimierung reduzieren
- Foreground-Notification ist immer sichtbar

## Nächste Schritte

1. **Testing**: Umfassende Tests auf verschiedenen Geräten
2. **Batterie-Optimierung**: Monitoring des Batterieverbrauchs
3. **Fallback-Mechanismus**: Implementierung von alternativen Tracking-Methoden
4. **Benutzer-Feedback**: Sammeln von Erfahrungsberichten

## Troubleshooting

### GPS-Tracking stoppt im Hintergrund

1. Berechtigungen prüfen (Settings > Apps > Mein Weg > Berechtigungen)
2. Batterie-Optimierung deaktivieren
3. App neu starten
4. GPS-Einstellungen prüfen (Standort-Dienste aktiviert)

### Keine GPS-Punkte

1. GPS-Genauigkeit prüfen (offener Himmel, keine Gebäude)
2. Bewegung prüfen (mindestens 2m)
3. App-Logs prüfen für Fehlermeldungen
4. Gerät neu starten

### Hoher Batterieverbrauch

1. `distanceFilter` auf 3-5m erhöhen
2. `intervalDuration` auf 5-8 Sekunden erhöhen
3. `enableWakeLock` auf `false` setzen (Android)
4. Batterie-Optimierung aktivieren
