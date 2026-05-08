import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ImageService {
  static Future<String> savePickedImage(String tempPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${dir.path}/product_images');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    final fileName = tempPath.split('/').last;
    final destPath = '${imageDir.path}/$fileName';
    await File(tempPath).copy(destPath);
    return destPath;
  }

  static Future<void> deleteImage(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static bool fileExists(String? path) {
    if (path == null) return false;
    return File(path).existsSync();
  }
}
