import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> requestInitialPermissions() async {
    // Basis-Berechtigungen beim App-Start anfordern
    await requestLocationPermission();
    await requestStoragePermission();
  }

  static Future<bool> requestLocationPermission() async {
    PermissionStatus status = await Permission.location.status;
    
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    
    return status.isGranted;
  }

  static Future<bool> requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.status;
    
    if (status.isDenied) {
      status = await Permission.camera.request();
    }
    
    return status.isGranted;
  }

  static Future<bool> requestStoragePermission() async {
    PermissionStatus status = await Permission.storage.status;
    
    if (status.isDenied) {
      status = await Permission.storage.request();
    }
    
    return status.isGranted;
  }

  static Future<bool> requestActivityRecognitionPermission() async {
    PermissionStatus status = await Permission.activityRecognition.status;
    
    if (status.isDenied) {
      status = await Permission.activityRecognition.request();
    }
    
    return status.isGranted;
  }

  static Future<bool> requestPhotosPermission() async {
    PermissionStatus status = await Permission.photos.status;
    
    if (status.isDenied) {
      status = await Permission.photos.request();
    }
    
    return status.isGranted;
  }

  static Future<bool> checkLocationPermission() async {
    return await Permission.location.isGranted;
  }

  static Future<bool> checkCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  static Future<bool> checkStoragePermission() async {
    return await Permission.storage.isGranted;
  }

  static Future<bool> checkActivityRecognitionPermission() async {
    return await Permission.activityRecognition.isGranted;
  }

  static Future<bool> checkPhotosPermission() async {
    return await Permission.photos.isGranted;
  }

  static Future<bool> checkAllRequiredPermissions() async {
    bool location = await checkLocationPermission();
    bool camera = await checkCameraPermission();
    bool storage = await checkStoragePermission();
    bool activityRecognition = await checkActivityRecognitionPermission();
    bool photos = await checkPhotosPermission();

    return location && camera && storage && activityRecognition && photos;
  }

  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  static String getPermissionExplanation(Permission permission) {
    switch (permission) {
      case Permission.location:
        return 'Die App benötigt Zugriff auf den Standort, um Ihre Etappen mit GPS zu verfolgen.';
      case Permission.camera:
        return 'Die App benötigt Zugriff auf die Kamera, um Bilder während Ihrer Etappen aufzunehmen.';
      case Permission.storage:
        return 'Die App benötigt Zugriff auf den Speicher, um Bilder und Dateien zu speichern.';
      case Permission.activityRecognition:
        return 'Die App benötigt Zugriff auf Aktivitätserkennung, um Ihre Schritte zu zählen.';
      case Permission.photos:
        return 'Die App benötigt Zugriff auf Fotos, um Bilder aus Ihrer Galerie zu importieren.';
      default:
        return 'Diese Berechtigung ist für die volle Funktionalität der App erforderlich.';
    }
  }
} 