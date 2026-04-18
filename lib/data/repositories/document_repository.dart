import 'dart:io';
import 'package:imprint/core/constants.dart';
import 'package:imprint/data/models/document.dart';
import 'package:imprint/data/serialization/imp_serializer.dart';
import 'package:imprint/services/file_picker_service.dart';

class DocumentRepository {
  DocumentRepository._();

  /// Opens a file picker and reads the selected `.imp` file.
  /// Returns null if the user cancels.
  static Future<({Document document, String path})?> open() async {
    final path = await FilePickerService.pickOpenFile(
      title: 'Open document',
      extensions: [kFileExtension],
    );
    if (path == null) return null;
    return _readFile(path);
  }

  /// Reads a `.imp` file at the given path directly (used for recent files).
  static Future<({Document document, String path})?> openPath(String path) async {
    final file = File(path);
    if (!file.existsSync()) return null;
    return _readFile(path);
  }

  static Future<({Document document, String path})> _readFile(String path) async {
    try {
      final content = await File(path).readAsString();
      final document = ImpSerializer.fromYaml(content);
      return (document: document, path: path);
    } on ImpSerializerException {
      rethrow;
    } catch (e) {
      throw ImpSerializerException('Could not read "$path": $e');
    }
  }

  /// Saves [document] to [currentPath]. If [currentPath] is null, opens a
  /// save-as dialog. Returns the saved path, or null if the user cancels.
  static Future<String?> save(Document document, String? currentPath) async {
    final path = currentPath ?? await _pickSavePath('document.$kFileExtension');
    if (path == null) return null;
    final yaml = ImpSerializer.toYaml(document);
    await File(path).writeAsString(yaml);
    return path;
  }

  /// Always opens the save-as dialog, ignoring any existing file path.
  static Future<String?> saveAs(Document document) async {
    final path = await _pickSavePath('document.$kFileExtension');
    if (path == null) return null;
    final yaml = ImpSerializer.toYaml(document);
    await File(path).writeAsString(yaml);
    return path;
  }

  static Future<String?> _pickSavePath(String defaultName) =>
      FilePickerService.pickSaveFile(
        title: 'Save document',
        defaultName: defaultName,
      );
}
