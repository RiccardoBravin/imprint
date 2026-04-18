import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imprint/core/pdf_format.dart';
import 'package:imprint/data/models/document.dart';
import 'package:imprint/data/models/section.dart';
import 'package:imprint/presentation/providers/document_provider.dart';
import 'package:imprint/presentation/screens/home_screen.dart';
import 'package:imprint/presentation/widgets/add_section_dialog.dart';
import 'package:imprint/presentation/widgets/app_logo.dart';
import 'package:imprint/presentation/widgets/editors/section_editor.dart';
import 'package:imprint/presentation/widgets/pdf_preview_dialog.dart';
import 'package:imprint/presentation/widgets/pdf_preview_pane.dart';
import 'package:imprint/presentation/widgets/section_settings_popup.dart';
import 'package:imprint/presentation/widgets/settings_popup.dart';
import 'package:imprint/presentation/widgets/split_view.dart';
import 'package:imprint/presentation/widgets/upload_dialog.dart';
import 'package:imprint/services/pdf/pdf_service.dart';
import 'package:imprint/services/print_service.dart';
import 'package:window_manager/window_manager.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> with WindowListener {
  int? _selectedSectionIndex;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.setPreventClose(true);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    final isDirty = ref.read(documentProvider).isDirty;
    if (isDirty) {
      final action = await _showUnsavedDialog();
      if (action == _UnsavedAction.save) {
        final saved = await ref.read(documentProvider.notifier).save();
        if (saved) await windowManager.destroy();
      } else if (action == _UnsavedAction.discard) {
        await windowManager.destroy();
      }
    } else {
      await windowManager.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    final docState = ref.watch(documentProvider);
    final title = docState.displayName + (docState.isDirty ? ' *' : '');

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Column(
            children: [
              _TitleBar(
                title: title,
                onHome: _navigateHome,
                onSettings: _openSettings,
                showPreview: _showPreview,
                onTogglePreview: () =>
                    setState(() => _showPreview = !_showPreview),
              ),
              Expanded(
                child: Row(
                  children: [
                    _Sidebar(
                      selectedIndex: _selectedSectionIndex,
                      onSelect: (i) => setState(() => _selectedSectionIndex = i),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: _showPreview
                          ? SplitView(
                              left: _MainArea(
                                selectedIndex: _selectedSectionIndex,
                              ),
                              right: const PdfPreviewPane(),
                              initialFraction: 0.55,
                            )
                          : _MainArea(selectedIndex: _selectedSectionIndex),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _BottomToolbar(onSave: _save),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    await ref.read(documentProvider.notifier).save();
  }

  Future<void> _openSettings() async {
    await SettingsPopup.show(context);
  }

  Future<void> _navigateHome() async {
    final isDirty = ref.read(documentProvider).isDirty;
    if (isDirty) {
      final action = await _showUnsavedDialog();
      if (action == _UnsavedAction.save) {
        final saved = await ref.read(documentProvider.notifier).save();
        if (!saved) return;
      } else if (action == _UnsavedAction.cancel) {
        return;
      }
    }
    if (!mounted) return;
    ref.read(documentProvider.notifier).close();
    unawaited(Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    ));
  }

  Future<_UnsavedAction?> _showUnsavedDialog() {
    final docState = ref.read(documentProvider);
    return showDialog<_UnsavedAction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: Text(
          '${docState.displayName} has unsaved changes.\n'
          'Do you want to save before closing?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _UnsavedAction.discard),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _UnsavedAction.cancel),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _UnsavedAction.save),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

enum _UnsavedAction { save, discard, cancel }

// ---------------------------------------------------------------------------
// Title bar
// ---------------------------------------------------------------------------

class _TitleBar extends StatelessWidget {
  const _TitleBar({
    required this.title,
    required this.onHome,
    required this.onSettings,
    required this.showPreview,
    required this.onTogglePreview,
  });

  final String title;
  final VoidCallback onHome;
  final VoidCallback onSettings;
  final bool showPreview;
  final VoidCallback onTogglePreview;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Tooltip(
            message: 'Home',
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onHome,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: ImprintIcon(size: 28),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: onSettings,
          ),
          IconButton(
            isSelected: showPreview,
            selectedIcon: const Icon(Icons.vertical_split),
            icon: const Icon(Icons.vertical_split_outlined),
            tooltip: showPreview ? 'Hide preview' : 'Show preview',
            onPressed: onTogglePreview,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar
// ---------------------------------------------------------------------------

class _Sidebar extends ConsumerWidget {
  const _Sidebar({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections =
        ref.watch(documentProvider).document?.sections ?? const [];

    return SizedBox(
      width: 300,
      child: Column(
        children: [
          Expanded(
            child: sections.isEmpty
                ? _EmptySidebar(onAdd: () => _addSection(context, ref, sections))
                : ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: sections.length,
                    onReorderItem: (oldIndex, newIndex) {
                      ref
                          .read(documentProvider.notifier)
                          .reorderSections(oldIndex, newIndex);
                    },
                    itemBuilder: (ctx, i) => _SectionTile(
                      key: ValueKey(sections[i].id),
                      index: i,
                      section: sections[i],
                      isSelected: selectedIndex == i,
                      onTap: () => onSelect(i),
                    ),
                  ),
          ),
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: const Icon(Icons.add),
            title: const Text('Add Section'),
            onTap: () => _addSection(context, ref, sections),
          ),
        ],
      ),
    );
  }

  Future<void> _addSection(
    BuildContext context,
    WidgetRef ref,
    List<Section> sections,
  ) async {
    final section = await AddSectionDialog.show(context);
    if (section == null) return;
    ref.read(documentProvider.notifier).addSection(section);
  }
}

class _EmptySidebar extends StatelessWidget {
  const _EmptySidebar({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No sections yet.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add first section'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section tile — direct inline action buttons on hover
// ---------------------------------------------------------------------------

class _SectionTile extends ConsumerStatefulWidget {
  const _SectionTile({
    super.key,
    required this.index,
    required this.section,
    required this.isSelected,
    required this.onTap,
  });

  final int index;
  final Section section;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  ConsumerState<_SectionTile> createState() => _SectionTileState();
}

class _SectionTileState extends ConsumerState<_SectionTile> {
  bool _isHovered = false;

  void _toggleHidden() {
    final s = widget.section;
    final updated = switch (s) {
      RegularSection s => s.copyWith(hidden: !s.hidden),
      SpecialSelection s => s.copyWith(hidden: !s.hidden),
      WineSection s => s.copyWith(hidden: !s.hidden),
      EventSection s => s.copyWith(hidden: !s.hidden),
      CoverSection s => s.copyWith(hidden: !s.hidden),
    };
    ref.read(documentProvider.notifier).updateSection(widget.index, updated);
  }

  void _duplicate() {
    ref.read(documentProvider.notifier).addSection(widget.section);
  }

  void _editSettings() {
    // Use addPostFrameCallback so the dialog opens after the current frame,
    // avoiding any potential layout/focus conflicts.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final updated =
          await SectionSettingsPopup.show(context, widget.section);
      if (!mounted || updated == null) return;
      ref.read(documentProvider.notifier).updateSection(widget.index, updated);
    });
  }

  void _delete() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete section?'),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      ref.read(documentProvider.notifier).removeSection(widget.index);
    });
  }


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: ListTile(
        dense: true,
        selected: widget.isSelected,
        selectedTileColor: cs.primaryContainer,
        contentPadding: const EdgeInsets.only(left: 4, right: 4),
        leading: ReorderableDragStartListener(
          index: widget.index,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: const Icon(Icons.drag_handle, size: 18),
          ),
        ),
        title: Text(
          widget.section.name.isNotEmpty ? widget.section.name : '(untitled)',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: widget.section.hidden ? cs.onSurfaceVariant : null,
          ),
        ),
        subtitle: Text(
          widget.section.typeKey,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        trailing: _isHovered
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconBtn(
                    icon: widget.section.hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    tooltip: widget.section.hidden ? 'Show' : 'Hide',
                    onPressed: _toggleHidden,
                  ),
                  _IconBtn(
                    icon: Icons.tune_outlined,
                    tooltip: 'Layout settings',
                    onPressed: _editSettings,
                  ),
                  _IconBtn(
                    icon: Icons.copy_outlined,
                    tooltip: 'Duplicate',
                    onPressed: _duplicate,
                  ),
                  _IconBtn(
                    icon: Icons.delete_outline,
                    tooltip: 'Delete',
                    color: cs.error,
                    onPressed: _delete,
                  ),
                ],
              )
            : widget.section.hidden
                ? Icon(
                    Icons.visibility_off_outlined,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  )
                : null,
        onTap: widget.onTap,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main area
// ---------------------------------------------------------------------------

class _MainArea extends ConsumerWidget {
  const _MainArea({required this.selectedIndex});

  final int? selectedIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doc = ref.watch(documentProvider).document;

    if (doc == null || selectedIndex == null) {
      return Center(
        child: Text(
          doc == null || doc.sections.isEmpty
              ? 'Add a section to get started.'
              : 'Select a section from the sidebar.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return SectionEditor(sectionIndex: selectedIndex!);
  }
}

// ---------------------------------------------------------------------------
// Bottom toolbar
// ---------------------------------------------------------------------------

class _BottomToolbar extends ConsumerWidget {
  const _BottomToolbar({required this.onSave});

  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (doc, isDirty, displayName) = ref.watch(
      documentProvider.select((s) => (s.document, s.isDirty, s.displayName)),
    );
    final s3Enabled = doc?.settings.enableS3Upload ?? true;

    return Container(
      height: 48,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: doc == null
                ? null
                : () => PdfPreviewDialog.show(context, doc),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Preview PDF'),
          ),
          TextButton.icon(
            onPressed: doc == null ? null : () => _print(context, doc, displayName),
            icon: const Icon(Icons.print_outlined),
            label: const Text('Print'),
          ),
          if (s3Enabled)
            TextButton.icon(
              onPressed: doc == null
                  ? null
                  : () => UploadDialog.show(context, doc),
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Upload'),
            ),
          const Spacer(),
          FilledButton.icon(
            onPressed: isDirty ? onSave : null,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _print(BuildContext context, Document document, String name) async {
    final settings = document.settings;
    final enableA4 = settings.enableA4;
    final enableA5 = settings.enableA5;

    PdfFormat? format;

    if (enableA4 && !enableA5) {
      format = PdfFormat.a4;
    } else if (enableA5 && !enableA4) {
      format = PdfFormat.a5;
    } else {
      // Both enabled — ask the user.
      if (!context.mounted) return;
      format = await showDialog<PdfFormat>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Print format'),
          content: const Text('Choose the paper format for printing.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, PdfFormat.a5),
              child: const Text('A5'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, PdfFormat.a4),
              child: const Text('A4'),
            ),
          ],
        ),
      );
    }

    if (format == null) return;
    final bytes = await PdfService.render(document, format);
    await PrintService.printPdf(bytes, name: name);
  }
}

// ---------------------------------------------------------------------------
// Compact icon button used in the section tile action row
// ---------------------------------------------------------------------------

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 16,
      tooltip: tooltip,
      icon: Icon(icon, color: color),
      onPressed: onPressed,
    );
  }
}
