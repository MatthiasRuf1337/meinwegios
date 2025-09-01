# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in /Users/flutter/flutter/packages/flutter_tools/gradle/flutter.gradle
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Camera
-keep class io.flutter.plugins.camera.** { *; }

# Audio recording
-keep class com.llfbandit.record.** { *; }

# PDF viewer
-keep class com.github.barteksc.pdfviewer.** { *; }

# Permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# SQLite
-keep class com.tekartik.sqflite.** { *; }
