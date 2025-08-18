import 'dart:io';
import 'package:flutter/material.dart';
import '../models/medien_datei.dart';

class ThumbnailService {
  static const String _thumbnailPath = 'assets/images/';

  /// Lädt ein Thumbnail für eine MP3-Datei
  static Widget loadThumbnail(
    MedienDatei medienDatei, {
    double width = 200,
    double height = 200,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    if (medienDatei.typ != MedienTyp.mp3) {
      return _buildDefaultIcon(width, height, borderRadius);
    }

    // Erstelle Thumbnail-Namen basierend auf MP3-Dateinamen
    final baseName = medienDatei.dateiname.replaceAll('.mp3', '');
    final thumbnailName = 'Thumbnail_$baseName.jpg';
    final assetPath = 'assets/images/$thumbnailName';

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
            // Fallback zu Standard-Icon wenn Thumbnail nicht gefunden wird
            return _buildDefaultIcon(width, height, borderRadius);
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
    if (medienDatei.typ != MedienTyp.mp3) {
      return _buildDefaultListIcon(width, height, borderRadius);
    }

    // Erstelle Thumbnail-Namen basierend auf MP3-Dateinamen
    final baseName = medienDatei.dateiname.replaceAll('.mp3', '');
    final thumbnailName = 'Thumbnail_$baseName.jpg';
    final assetPath = 'assets/images/$thumbnailName';

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
            return _buildDefaultListIcon(width, height, borderRadius);
          },
        ),
      ),
    );
  }

  /// Erstellt ein Standard-Icon für MP3-Dateien ohne Thumbnail
  static Widget _buildDefaultIcon(
      double width, double height, BorderRadius? borderRadius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Color(0xFF00847E),
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
        Icons.music_note,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  /// Erstellt ein Standard-Icon für Listen
  static Widget _buildDefaultListIcon(
      double width, double height, BorderRadius? borderRadius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.audiotrack,
        color: Colors.blue.shade600,
        size: 24,
      ),
    );
  }

  /// Prüft ob ein Thumbnail für eine MP3-Datei verfügbar ist
  static bool hasThumbnail(MedienDatei medienDatei) {
    if (medienDatei.typ != MedienTyp.mp3) return false;

    // Erstelle Thumbnail-Namen basierend auf MP3-Dateinamen
    final baseName = medienDatei.dateiname.replaceAll('.mp3', '');
    final thumbnailName = 'Thumbnail_$baseName.jpg';

    // Prüfe ob das Asset verfügbar ist (für die bekannten Thumbnails)
    return thumbnailName == 'Thumbnail_3 Minuten Atemraum.jpg' ||
        thumbnailName == 'Thumbnail_Atem Ruhe Freundlichkeit.jpg';
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
