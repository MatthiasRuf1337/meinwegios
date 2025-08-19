import 'dart:io';
import 'package:flutter/material.dart';
import '../models/medien_datei.dart';

class ThumbnailService {
  static const String _thumbnailPath = 'assets/images/';

  /// Lädt ein Thumbnail für eine MP3- oder PDF-Datei
  static Widget loadThumbnail(
    MedienDatei medienDatei, {
    double width = 200,
    double height = 200,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    if (medienDatei.typ != MedienTyp.mp3 && medienDatei.typ != MedienTyp.pdf) {
      return _buildDefaultIcon(medienDatei, width, height, borderRadius);
    }

    // Erstelle Thumbnail-Namen basierend auf Dateinamen
    String baseName;
    if (medienDatei.typ == MedienTyp.mp3) {
      baseName = medienDatei.dateiname.replaceAll('.mp3', '');
    } else {
      baseName =
          medienDatei.dateiname.replaceAll('.pdf', '').replaceAll(' ', '_');
    }
    final thumbnailName = 'Thumbnail_$baseName.jpg';
    final assetPath = 'assets/images/$thumbnailName';
    
    // Debug-Ausgabe
    print('🖼️ Thumbnail Debug - Datei: ${medienDatei.dateiname}');
    print('🖼️ Thumbnail Debug - BaseName: $baseName');
    print('🖼️ Thumbnail Debug - ThumbnailName: $thumbnailName');
    print('🖼️ Thumbnail Debug - AssetPath: $assetPath');

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: Image.asset(
          assetPath,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            // Debug-Ausgabe bei Asset-Fehler
            print('❌ Asset-Fehler für: $assetPath');
            print('❌ Fehler: $error');
            // Fallback zu Standard-Icon wenn Thumbnail nicht gefunden wird
            return _buildDefaultIcon(medienDatei, width, height, borderRadius);
          },
        ),
      ),
    );
  }

  /// Lädt ein kleines Thumbnail für Listen
  static Widget loadListThumbnail(
    MedienDatei medienDatei, {
    double width = 50,
    double height = 50,
    BorderRadius? borderRadius,
  }) {
    if (medienDatei.typ != MedienTyp.mp3 && medienDatei.typ != MedienTyp.pdf) {
      return _buildDefaultListIcon(medienDatei, width, height, borderRadius);
    }

    // Erstelle Thumbnail-Namen basierend auf Dateinamen
    String baseName;
    if (medienDatei.typ == MedienTyp.mp3) {
      baseName = medienDatei.dateiname.replaceAll('.mp3', '');
    } else {
      baseName =
          medienDatei.dateiname.replaceAll('.pdf', '').replaceAll(' ', '_');
    }
    final thumbnailName = 'Thumbnail_$baseName.jpg';
    final assetPath = 'assets/images/$thumbnailName';
    
    // Debug-Ausgabe für Listen-Thumbnails
    print('📋 List Thumbnail Debug - Datei: ${medienDatei.dateiname}');
    print('📋 List Thumbnail Debug - BaseName: $baseName');
    print('📋 List Thumbnail Debug - ThumbnailName: $thumbnailName');
    print('📋 List Thumbnail Debug - AssetPath: $assetPath');

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Debug-Ausgabe bei Asset-Fehler für Listen-Thumbnails
            print('❌ List Asset-Fehler für: $assetPath');
            print('❌ List Fehler: $error');
            return _buildDefaultListIcon(
                medienDatei, width, height, borderRadius);
          },
        ),
      ),
    );
  }

  /// Erstellt ein Standard-Icon für Dateien ohne Thumbnail
  static Widget _buildDefaultIcon(MedienDatei medienDatei, double width,
      double height, BorderRadius? borderRadius) {
    Color backgroundColor;
    IconData iconData;

    if (medienDatei.typ == MedienTyp.mp3) {
      backgroundColor = Color(0xFF00847E);
      iconData = Icons.music_note;
    } else if (medienDatei.typ == MedienTyp.pdf) {
      backgroundColor = Colors.red.shade600;
      iconData = Icons.picture_as_pdf;
    } else {
      backgroundColor = Colors.grey.shade600;
      iconData = Icons.insert_drive_file;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Icon(
        iconData,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  /// Erstellt ein Standard-Icon für Listen
  static Widget _buildDefaultListIcon(MedienDatei medienDatei, double width,
      double height, BorderRadius? borderRadius) {
    Color backgroundColor;
    Color iconColor;
    IconData iconData;

    if (medienDatei.typ == MedienTyp.mp3) {
      backgroundColor = Colors.blue.shade100;
      iconColor = Colors.blue.shade600;
      iconData = Icons.audiotrack;
    } else if (medienDatei.typ == MedienTyp.pdf) {
      backgroundColor = Colors.red.shade100;
      iconColor = Colors.red.shade600;
      iconData = Icons.picture_as_pdf;
    } else {
      backgroundColor = Colors.grey.shade100;
      iconColor = Colors.grey.shade600;
      iconData = Icons.insert_drive_file;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  /// Prüft ob ein Thumbnail für eine MP3- oder PDF-Datei verfügbar ist
  static bool hasThumbnail(MedienDatei medienDatei) {
    if (medienDatei.typ != MedienTyp.mp3 && medienDatei.typ != MedienTyp.pdf)
      return false;

    // Erstelle Thumbnail-Namen basierend auf Dateinamen
    String baseName;
    if (medienDatei.typ == MedienTyp.mp3) {
      baseName = medienDatei.dateiname.replaceAll('.mp3', '');
    } else {
      baseName =
          medienDatei.dateiname.replaceAll('.pdf', '').replaceAll(' ', '_');
    }
    final thumbnailName = 'Thumbnail_$baseName.jpg';

    // Prüfe ob das Asset verfügbar ist (für die bekannten Thumbnails)
    final knownThumbnails = [
      'Thumbnail_3 Minuten Atemraum.jpg',
      'Thumbnail_Atem Ruhe Freundlichkeit.jpg',
      'Thumbnail_Die_Magie_des_Pilgerns.jpg',
      'Thumbnail_Mache_dich_auf_den_Weg.jpg',
      'Thumbnail_Packliste.jpg',
    ];

    return knownThumbnails.contains(thumbnailName);
  }

  /// Gibt eine Liste aller verfügbaren Thumbnails zurück
  static List<String> getAvailableThumbnails() {
    final directory = Directory(_thumbnailPath);
    if (!directory.existsSync()) {
      return [];
    }

    final files = directory.listSync();
    return files
        .where((file) =>
            file is File &&
            (file.path.endsWith('.jpg') || file.path.endsWith('.png')))
        .map((file) => file.path)
        .toList();
  }

  /// Debug-Funktion: Zeigt alle verfügbaren Thumbnails an
  static void debugThumbnails() {
    print('=== Verfügbare Thumbnails ===');
    final thumbnails = getAvailableThumbnails();
    for (final thumbnail in thumbnails) {
      print('Thumbnail: $thumbnail');
    }
    print('============================');
  }
}
