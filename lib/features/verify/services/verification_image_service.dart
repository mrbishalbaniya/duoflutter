import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';

class VerificationImageService {
  Future<File> compressForUpload(File source) async {
    final targetPath =
        '${source.parent.path}${Platform.pathSeparator}verify_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final compressed = await FlutterImageCompress.compressAndGetFile(
      source.absolute.path,
      targetPath,
      quality: 88,
      minWidth: 1280,
      minHeight: 720,
      format: CompressFormat.jpeg,
    );

    return compressed != null ? File(compressed.path) : source;
  }
}
