import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io';

class FaceRecognitionService {
  static Future<String> analyzeFace(File image) async {
    try {
      final inputImage = InputImage.fromFile(image);
      final faceDetector = GoogleMlKit.vision.faceDetector(
        FaceDetectorOptions(
          enableClassification: true,
          enableLandmarks: true,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);
      faceDetector.close();

      if (faces.isEmpty) {
        return 'No faces detected.';
      }

      final face = faces.first;
      String result = 'Face detected:\n';
      if (face.smilingProbability != null) {
        result += face.smilingProbability! > 0.5
            ? '- Appears to be smiling\n'
            : '- Not smiling\n';
      }
      if (face.leftEyeOpenProbability != null) {
        result += face.leftEyeOpenProbability! > 0.5
            ? '- Left eye open\n'
            : '- Left eye closed\n';
      }
      if (face.rightEyeOpenProbability != null) {
        result += face.rightEyeOpenProbability! > 0.5
            ? '- Right eye open\n'
            : '- Right eye closed\n';
      }

      return result;
    } catch (e) {
      return 'Error analyzing face: $e';
    }
  }
}