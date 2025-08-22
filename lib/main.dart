import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import 'models/etappe.dart';
import 'models/bild.dart';
import 'models/medien_datei.dart';
import 'models/app_settings.dart';
import 'providers/etappen_provider.dart';
import 'providers/bilder_provider.dart';
import 'providers/medien_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/notiz_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_navigation.dart';
import 'services/database_service.dart';
import 'services/permission_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Datenbank initialisieren
  await DatabaseService.instance.initDatabase();

  // Vorab geladene Medien (PDFs und MP3s) importieren
  await DatabaseService.instance.importPreloadedMedia();

  // Berechtigungen werden später manuell angefordert
  print('App gestartet - Berechtigungen werden manuell angefordert');

  runApp(MeinWegApp());
}

class MeinWegApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => EtappenProvider()),
        ChangeNotifierProvider(create: (_) => BilderProvider()),
        ChangeNotifierProvider(create: (_) => MedienProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => NotizProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: 'Mein Weg',
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [
              Locale('de', 'DE'), // Deutsch
              Locale('en', 'US'), // Englisch als Fallback
            ],
            locale: Locale('de', 'DE'), // Standard auf Deutsch setzen
            theme: ThemeData(
              fontFamily: 'MuseoSans',
              colorScheme: ColorScheme.light(
                primary: Color(0xFF5A7D7D),
              ),
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              fontFamily: 'MuseoSans',
              colorScheme: ColorScheme.dark(
                primary: Color(0xFF5A7D7D),
              ),
              brightness: Brightness.dark,
            ),
            home: settingsProvider.isFirstAppUsage
                ? OnboardingScreen()
                : MainNavigation(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
