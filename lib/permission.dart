import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:camera/camera.dart';

class PermissionService {
  static Future<bool> requestCameraPermission() async {
    if (Platform.isLinux) {
      try {
        final cameras = await availableCameras();
        if (cameras.isNotEmpty) {
          print('Linux: Camera access available');
          return true;
        } else {
          print('Linux: No cameras detected');
          return false;
        }
      } catch (e) {
        print('Linux: Camera access error: $e');
        return false;
      }
    } else {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        print('Camera permission granted');
        return true;
      } else if (status.isPermanentlyDenied) {
        print('Camera permission permanently denied');
        await openAppSettings();
        return false;
      }
      print('Camera permission denied');
      return false;
    }
  }

  static Future<bool> requestMicrophonePermission() async {
    if (Platform.isLinux) {
      try {
        final micDevice = File('/dev/snd/controlC0');
        if (await micDevice.exists()) {
          print('Linux: Microphone access likely available');
          return true;
        } else {
          print('Linux: No microphone device detected');
          return false;
        }
      } catch (e) {
        print('Linux: Microphone access error: $e');
        return false;
      }
    } else {
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        print('Microphone permission granted');
        return true;
      } else if (status.isPermanentlyDenied) {
        print('Microphone permission permanently denied');
        await openAppSettings();
        return false;
      }
      print('Microphone permission denied');
      return false;
    }
  }
}