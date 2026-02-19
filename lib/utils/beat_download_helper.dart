import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../beats/beat_model.dart';

class BeatDownloadHelper {
  static Future<String> downloadBeatFile(BeatModel beat) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory("${docsDir.path}/downloads");
    if (!downloadDir.existsSync()) {
      downloadDir.createSync(recursive: true);
    }

    final extension = _fileExtension(beat.audioPath);
    final safeName = _safeFileName(beat.title);
    final outputPath = _uniqueOutputPath(downloadDir.path, safeName, extension);
    final outputFile = File(outputPath);

    if (beat.audioPath.startsWith("assets/")) {
      final assetPath = beat.audioPath.replaceFirst("assets/", "");
      final data = await rootBundle.load("assets/$assetPath");
      await outputFile.writeAsBytes(data.buffer.asUint8List());
    } else {
      final sourceFile = File(beat.audioPath);
      if (!sourceFile.existsSync()) {
        throw Exception("Audio source file not found");
      }
      if (sourceFile.absolute.path == outputFile.absolute.path) {
        return outputFile.path;
      }
      await sourceFile.copy(outputPath);
    }

    return outputPath;
  }

  static Future<void> downloadWithFeedback({
    required BuildContext context,
    required BeatModel beat,
  }) async {
    try {
      final savedPath = await downloadBeatFile(beat);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Downloaded to: $savedPath")),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not download beat. Source file may be missing.")),
      );
    }
  }

  static String _safeFileName(String value) {
    return value.replaceAll(RegExp(r'[<>:"/\\|?*]'), "_");
  }

  static String _fileExtension(String path) {
    final dot = path.lastIndexOf(".");
    if (dot == -1 || dot == path.length - 1) {
      return ".mp3";
    }
    return path.substring(dot);
  }

  static String _uniqueOutputPath(String dirPath, String baseName, String ext) {
    var path = "$dirPath/$baseName$ext";
    var i = 1;
    while (File(path).existsSync()) {
      path = "$dirPath/${baseName}_$i$ext";
      i++;
    }
    return path;
  }
}
