import 'dart:io';
import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:flutter/cupertino.dart';
import 'package:pasteboard/pasteboard.dart';

import '../file.dart';
import '../logger.dart';

final _supportedPlatform =
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;

Future<List<File>> getClipboardFiles() async {
  if (!_supportedPlatform) {
    return const [];
  }

  try {
    final filePaths = await Pasteboard.files();
    if (filePaths.isNotEmpty) {
      final files =
          filePaths.map(File.new).where((e) => e.existsSync()).toList();
      if (files.isNotEmpty) {
        return files;
      }
    }
  } catch (error, stack) {
    e('Pasteboard.files: $error $stack');
  }

  Uint8List? imageBytes;
  try {
    imageBytes = await Pasteboard.image;
  } catch (error, stack) {
    e('Pasteboard.image: $error $stack');
  }

  if (imageBytes != null) {
    if (Platform.isWindows) {
      try {
        final image = await decodeImageFromList(imageBytes);
        final data = await image.toByteData(format: ImageByteFormat.png);
        if (data == null) {
          return const [];
        }
        imageBytes = Uint8List.view(data.buffer);
      } catch (error, s) {
        e('re format image failed: $error $s');
      }
    }
    final file =
        await saveBytesToTempFile(imageBytes!, TempFileType.pasteboardImage);
    if (file != null) {
      return [file];
    }
  }

  return const [];
}
