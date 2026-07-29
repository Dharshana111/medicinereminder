import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from camera or gallery.
  /// Returns the temporary file path, or null if cancelled.
  static Future<String?> pickImage({required bool fromCamera}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      return image?.path;
    } catch (_) {
      return null;
    }
  }

  /// Save an image from a temporary path to the app's documents directory.
  /// Returns the permanent file path.
  static Future<String> saveImage(String tempPath) async {
    if (kIsWeb) return tempPath;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${directory.path}/medicine_images');

      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      final fileName =
          'med_img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newPath = '${imageDir.path}/$fileName';

      final tempFile = File(tempPath);
      await tempFile.copy(newPath);

      return newPath;
    } catch (_) {
      return tempPath;
    }
  }

  /// Delete an image file if it exists.
  static Future<void> deleteImage(String path) async {
    if (kIsWeb) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Silently handle deletion errors
    }
  }
}
