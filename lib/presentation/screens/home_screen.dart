import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imprint/data/repositories/settings_repository.dart';
import 'package:imprint/presentation/providers/document_provider.dart';
import 'package:imprint/presentation/providers/settings_provider.dart';
import 'package:imprint/presentation/screens/editor_screen.dart';
import 'package:imprint/presentation/widgets/app_logo.dart';

// Async file info so build() never blocks on disk I/O.
final _fileInfoProvider = FutureProvider.autoDispose
    .family<({bool exists, String modifiedLabel}), String>((ref, path) async {
  final file = File(path);
  final exists = await file.exists();
  if (!exists) return (exists: false, modifiedLabel: '');
  try {
    final modified = await file.lastModified();
    final diff = DateTime.now().difference(modified);
    final String label;
    if (diff.inMinutes < 1) {
      label = 'Just now';
    } else if (diff.inHours < 1) {
      label = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      label = '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      label = 'Yesterday';
    } else {
      label = '${diff.inDays} days ago';
    }
    return (exists: true, modifiedLabel: label);
  } catch (_) {
    return (exists: true, modifiedLabel: '');
  }
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _AppTitle(),
              const SizedBox(height: 40),
              const _ActionButtons(),
              const SizedBox(height: 48),
              const _RecentFilesSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) {
    return const Center(child: ImprintLogo(iconSize: 72));
  }
}

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: () => _newDocument(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('New Document'),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => _openFile(context, ref),
          icon: const Icon(Icons.folder_open_outlined),
          label: const Text('Open File'),
        ),
      ],
    );
  }

  void _newDocument(BuildContext context, WidgetRef ref) {
    ref.read(documentProvider.notifier).newDocument();
    _navigateToEditor(context);
  }

  Future<void> _openFile(BuildContext context, WidgetRef ref) async {
    final (bool opened, String? error) = await ref.read(documentProvider.notifier).open();
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    if (!opened) return;
    _navigateToEditor(context);
  }

  void _navigateToEditor(BuildContext context) {
    unawaited(Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const EditorScreen()),
    ));
  }
}

class _RecentFilesSection extends ConsumerWidget {
  const _RecentFilesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentFilesProvider);

    return recent.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (files) {
        if (files.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Recent Files',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ...files.map((path) => _RecentFileTile(path: path)),
          ],
        );
      },
    );
  }
}

class _RecentFileTile extends ConsumerWidget {
  const _RecentFileTile({required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileInfo = ref.watch(_fileInfoProvider(path));
    final fileName = path.split('/').last.split('\\').last;

    return fileInfo.when(
      loading: () => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        leading: Icon(
          Icons.description_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(fileName),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (info) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        leading: Icon(
          Icons.description_outlined,
          color: info.exists
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(
          fileName,
          style: TextStyle(
            color: info.exists
                ? null
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle: Text(
          info.exists ? info.modifiedLabel : 'File not found',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: info.exists
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 16),
                tooltip: 'Remove from list',
                onPressed: () async {
                  await SettingsRepository.removeRecentFile(path);
                  ref.invalidate(recentFilesProvider);
                },
              ),
        onTap: info.exists ? () => _open(context, ref) : null,
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final (bool opened, String? error) = await ref.read(documentProvider.notifier).openPath(path);
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    if (!opened) return;
    unawaited(Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const EditorScreen()),
    ));
  }
}
