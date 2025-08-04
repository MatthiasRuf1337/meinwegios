# GitHub Repository Setup für App Store Connect

## 🎯 GitHub Repository erstellen

### 1. GitHub Repository erstellen

1. Gehen Sie zu [GitHub.com](https://github.com)
2. Klicken Sie auf "New repository"
3. Repository-Einstellungen:
   - **Repository name**: `meinweg-ios`
   - **Description**: `MeinWeg iOS App - Flutter project for hiking and tour tracking`
   - **Visibility**: Public (oder Private)
   - **☑️ Add a README file** (nicht aktivieren)
   - **☑️ Add .gitignore** (nicht aktivieren)
   - **☑️ Choose a license** (optional)

### 2. Repository mit GitHub verbinden

Nachdem Sie das Repository erstellt haben, führen Sie diese Befehle aus:

```bash
# Remote Repository hinzufügen (ersetzen Sie YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/meinweg-ios.git

# Branch umbenennen (optional)
git branch -M main

# Code hochladen
git push -u origin main
```

### 3. Repository URL für App Store Connect

Die URL für App Store Connect ist dann:

```
https://github.com/YOUR_USERNAME/meinweg-ios
```

## 📋 App Store Connect Setup

### Repository Information in App Store Connect:

- **Repository URL**: `https://github.com/YOUR_USERNAME/meinweg-ios`
- **Repository Name**: `meinweg-ios`
- **Description**: `MeinWeg iOS App - Flutter project for hiking and tour tracking`

### Wichtige Hinweise:

- ✅ Repository ist öffentlich oder privat (Apple kann darauf zugreifen)
- ✅ README.md ist vorhanden
- ✅ .gitignore ist konfiguriert
- ✅ Initial commit ist gemacht
- ✅ Flutter Projekt ist vollständig

## 🚀 Nächste Schritte

1. **GitHub Repository erstellen** (siehe oben)
2. **Code hochladen** (git push)
3. **App Store Connect**: Repository URL eingeben
4. **Archive hochladen**
5. **TestFlight Setup**

## 📞 Support

Bei Problemen:

- [GitHub Help](https://help.github.com/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
