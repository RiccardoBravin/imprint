import 'dart:io';

import 'package:file_picker/file_picker.dart';

class FilePickerService {
  FilePickerService._();

  static Future<String?> pickOpenFile({
    String title = 'Open file',
    List<String> extensions = const [],
  }) async {
    if (Platform.isLinux) {
      final args = ['--file-selection', '--title=$title'];
      if (extensions.isNotEmpty) {
        args.addAll(['--file-filter', extensions.map((e) => '*.$e').join(' ')]);
      }
      return _zenity(args);
    }
    final result = await FilePicker.pickFiles(
      dialogTitle: title,
      type: extensions.isEmpty ? FileType.any : FileType.custom,
      allowedExtensions: extensions.isEmpty ? null : extensions,
    );
    return result?.files.single.path;
  }

  static Future<String?> pickSaveFile({
    String title = 'Save file',
    String defaultName = 'document',
  }) async {
    if (Platform.isLinux) {
      return _zenity([
        '--file-selection',
        '--save',
        '--confirm-overwrite',
        '--title=$title',
        '--filename=$defaultName',
      ]);
    }
    return FilePicker.saveFile(dialogTitle: title, fileName: defaultName);
  }

  static Future<String?> pickImageFile({
    String title = 'Select image',
  }) async {
    if (Platform.isLinux) {
      return _zenity([
        '--file-selection',
        '--title=$title',
        '--file-filter=*.png *.jpg *.jpeg *.bmp *.gif *.webp',
      ]);
    }
    final result = await FilePicker.pickFiles(
      dialogTitle: title,
      type: FileType.image,
    );
    return result?.files.single.path;
  }

  static Future<String?> _zenity(List<String> args) async {
    try {
      final result = await Process.run('zenity', args);
      if (result.exitCode == 0) {
        final path = (result.stdout as String).trim();
        return path.isEmpty ? null : path;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
