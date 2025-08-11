import 'dart:io';
import 'package:permission_handler/permission_handler.dart' as ph;

class PermissionService {
  static Future<void> requestInitialPermissions() async {
    if (Platform.isIOS) {
      await requestLocationPermission();
      await requestCameraPermission();
      await requestPhotosPermission();
      await requestActivityRecognitionPermission();
    } else {
      await requestLocationPermission();
      await requestStoragePermission();
      await requestCameraPermission();
      await requestActivityRecognitionPermission();
      await requestPhotosPermission();
    }
  }

  static Future<bool> requestLocationPermission() async {
    ph.PermissionStatus status;
    if (Platform.isIOS) {
      status = await ph.Permission.locationWhenInUse.status;
      if (status.isDenied) {
        status = await ph.Permission.locationWhenInUse.request();
      }
    } else {
      status = await ph.Permission.location.status;
      if (status.isDenied) {
        status = await ph.Permission.location.request();
      }
    }
    return status.isGranted;
  }

  static Future<bool> requestCameraPermission() async {
    ph.PermissionStatus status = await ph.Permission.camera.status;
    if (status.isDenied) {
      status = await ph.Permission.camera.request();
    }
    return status.isGranted;
  }

  static Future<bool> requestStoragePermission() async {
    if (Platform.isIOS) {
      // iOS benötigt keine generische Speicher-Berechtigung
      return true;
    }
    ph.PermissionStatus status = await ph.Permission.storage.status;
    if (status.isDenied) {
      status = await ph.Permission.storage.request();
    }
    return status.isGranted;
  }

  static Future<bool> requestActivityRecognitionPermission() async {
    if (Platform.isIOS) {
      ph.PermissionStatus status = await ph.Permission.sensors.status;
      if (status.isDenied) {
        status = await ph.Permission.sensors.request();
      }
      return status.isGranted;
    } else {
      ph.PermissionStatus status =
          await ph.Permission.activityRecognition.status;
      if (status.isDenied) {
        status = await ph.Permission.activityRecognition.request();
      }
      return status.isGranted;
    }
  }

  static Future<bool> requestPhotosPermission() async {
    ph.PermissionStatus status = await ph.Permission.photos.status;
    if (status.isDenied) {
      status = await ph.Permission.photos.request();
    }
    return status.isGranted;
  }

  static Future<bool> checkLocationPermission() async {
    return Platform.isIOS
        ? await ph.Permission.locationWhenInUse.isGranted
        : await ph.Permission.location.isGranted;
  }

  static Future<bool> checkCameraPermission() async {
    return await ph.Permission.camera.isGranted;
  }

  static Future<bool> checkStoragePermission() async {
    return Platform.isIOS ? true : await ph.Permission.storage.isGranted;
  }

  static Future<bool> checkActivityRecognitionPermission() async {
    return Platform.isIOS
        ? await ph.Permission.sensors.isGranted
        : await ph.Permission.activityRecognition.isGranted;
  }

  static Future<bool> checkPhotosPermission() async {
    return await ph.Permission.photos.isGranted;
  }

  static Future<bool> checkAllRequiredPermissions() async {
    if (Platform.isIOS) {
      bool location = await checkLocationPermission();
      bool camera = await checkCameraPermission();
      bool sensors = await checkActivityRecognitionPermission();
      bool photos = await checkPhotosPermission();
      return location && camera && sensors && photos;
    } else {
      bool location = await checkLocationPermission();
      bool camera = await checkCameraPermission();
      bool storage = await checkStoragePermission();
      bool activityRecognition = await checkActivityRecognitionPermission();
      bool photos = await checkPhotosPermission();
      return location && camera && storage && activityRecognition && photos;
    }
  }

  // Keep backward-compatible API used elsewhere in the app
  static Future<void> openAppSettings() async {
    await ph.openAppSettings();
  }

  static Future<void> openSystemAppSettings() async {
    await ph.openAppSettings();
  }

  static String getPermissionExplanation(ph.Permission permission) {
    switch (permission) {
      case ph.Permission.location:
      case ph.Permission.locationWhenInUse:
        return 'Die App benötigt Zugriff auf den Standort, um Ihre Etappen mit GPS zu verfolgen.';
      case ph.Permission.camera:
        return 'Die App benötigt Zugriff auf die Kamera, um Bilder während Ihrer Etappen aufzunehmen.';
      case ph.Permission.storage:
        return 'Die App benötigt Zugriff auf den Speicher, um Bilder und Dateien zu speichern.';
      case ph.Permission.activityRecognition:
      case ph.Permission.sensors:
        return 'Die App benötigt Zugriff auf Bewegung & Fitness, um Ihre Schritte zu zählen.';
      case ph.Permission.photos:
        return 'Die App benötigt Zugriff auf Fotos, um Bilder aus Ihrer Galerie zu importieren.';
      default:
        return 'Diese Berechtigung ist für die volle Funktionalität der App erforderlich.';
    }
  }
}
