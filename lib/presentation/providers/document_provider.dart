import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imprint/data/models/document.dart';
import 'package:imprint/data/models/section.dart';
import 'package:imprint/data/repositories/document_repository.dart';
import 'package:imprint/data/repositories/settings_repository.dart';
import 'package:imprint/data/serialization/imp_serializer.dart';

class DocumentState {
  const DocumentState({
    this.document,
    this.filePath,
    this.isDirty = false,
  });

  final Document? document;
  final String? filePath;
  final bool isDirty;

  bool get isOpen => document != null;

  String get displayName {
    if (filePath == null) return 'Untitled';
    final base = filePath!.split('/').last.split('\\').last;
    if (base.endsWith('.imp')) return base.substring(0, base.length - 4);
    return base;
  }

  DocumentState copyWith({
    Document? document,
    String? filePath,
    bool? isDirty,
  }) => DocumentState(
    document: document ?? this.document,
    filePath: filePath ?? this.filePath,
    isDirty: isDirty ?? this.isDirty,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentState &&
          document == other.document &&
          filePath == other.filePath &&
          isDirty == other.isDirty;

  @override
  int get hashCode => Object.hash(document, filePath, isDirty);
}

class DocumentNotifier extends Notifier<DocumentState> {
  @override
  DocumentState build() => const DocumentState();

  void newDocument() {
    state = DocumentState(document: Document.empty(), isDirty: false);
  }

  Future<(bool, String?)> open() async {
    try {
      final result = await DocumentRepository.open();
      if (result == null) return (false, null);
      await SettingsRepository.addRecentFile(result.path);
      state = DocumentState(document: result.document, filePath: result.path);
      return (true, null);
    } on ImpSerializerException catch (e) {
      return (false, e.message);
    } catch (_) {
      return (false, 'Could not open the file.');
    }
  }

  Future<(bool, String?)> openPath(String path) async {
    try {
      final result = await DocumentRepository.openPath(path);
      if (result == null) return (false, null);
      await SettingsRepository.addRecentFile(result.path);
      state = DocumentState(document: result.document, filePath: result.path);
      return (true, null);
    } on ImpSerializerException catch (e) {
      return (false, e.message);
    } catch (_) {
      return (false, 'Could not open the file.');
    }
  }

  Future<bool> save() async {
    final doc = state.document;
    if (doc == null) return false;
    final path = await DocumentRepository.save(doc, state.filePath);
    if (path == null) return false;
    await SettingsRepository.addRecentFile(path);
    state = state.copyWith(filePath: path, isDirty: false);
    return true;
  }

  Future<bool> saveAs() async {
    final doc = state.document;
    if (doc == null) return false;
    final path = await DocumentRepository.saveAs(doc);
    if (path == null) return false;
    await SettingsRepository.addRecentFile(path);
    state = state.copyWith(filePath: path, isDirty: false);
    return true;
  }

  void close() {
    state = const DocumentState();
  }

  // ---------------------------------------------------------------------------
  // Document mutations — each marks the document dirty
  // ---------------------------------------------------------------------------

  void updateDocument(Document updated) {
    state = state.copyWith(document: updated, isDirty: true);
  }

  void updateSections(List<Section> sections) {
    final doc = state.document;
    if (doc == null) return;
    updateDocument(doc.copyWith(sections: sections));
  }

  void addSection(Section section) {
    final doc = state.document;
    if (doc == null) return;
    updateDocument(doc.copyWith(sections: [...doc.sections, section]));
  }

  void removeSection(int index) {
    final doc = state.document;
    if (doc == null) return;
    final sections = [...doc.sections]..removeAt(index);
    updateDocument(doc.copyWith(sections: sections));
  }

  void updateSection(int index, Section updated) {
    final doc = state.document;
    if (doc == null) return;
    final sections = [...doc.sections]..[index] = updated;
    updateDocument(doc.copyWith(sections: sections));
  }

  void reorderSections(int oldIndex, int newIndex) {
    final doc = state.document;
    if (doc == null) return;
    final sections = [...doc.sections];
    final item = sections.removeAt(oldIndex);
    sections.insert(newIndex, item);
    updateDocument(doc.copyWith(sections: sections));
  }
}

final documentProvider =
    NotifierProvider<DocumentNotifier, DocumentState>(DocumentNotifier.new);
