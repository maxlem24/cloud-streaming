// lib/core/permission_service.dart
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {

  static Future<void> ensurePermissions() async {
    if (Platform.isWindows || Platform.isMacOS) {
      await _requestCamera();
      await _requestMicrophone();
    }

  }

  static Future<PermissionStatus> _requestCamera() async {
    final status = await Permission.camera.status;
    if (status.isDenied || status.isRestricted) {
      return await Permission.camera.request();
    }
    return status;
  }

  static Future<PermissionStatus> _requestMicrophone() async {
    final status = await Permission.microphone.status;
    if (status.isDenied || status.isRestricted) {
      return await Permission.microphone.request();
    }
    return status;
  }

  static Future<PermissionStatus> getCameraStatus() async =>
      await Permission.camera.status;

  static Future<PermissionStatus> getMicStatus() async =>
      await Permission.microphone.status;
}
