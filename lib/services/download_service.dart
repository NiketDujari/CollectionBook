import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService {

  // static Future<bool> savePdf(
  //     String filename,
  //     Uint8List bytes,
  //     ) async {
  //   try {
  //     final tempDir = await getTemporaryDirectory();
  //
  //     final tempFile = File("${tempDir.path}/$filename");
  //
  //     await tempFile.writeAsBytes(bytes);
  //
  //     final mediaStore = MediaStore();
  //
  //     final saveInfo = await mediaStore.saveFile(
  //       tempFilePath: tempFile.path,
  //       dirType: DirType.download,
  //       dirName: DirName.download,
  //     );
  //
  //     return saveInfo != null && saveInfo.isSuccessful;
  //   } catch (e) {
  //     debugPrint("Save PDF Error: $e");
  //     return false;
  //   }
  // }

}