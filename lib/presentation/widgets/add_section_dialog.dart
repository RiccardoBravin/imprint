import 'package:flutter/material.dart';
import 'package:imprint/data/models/section.dart';

class AddSectionDialog extends StatelessWidget {
  const AddSectionDialog({super.key});

  static Future<Section?> show(BuildContext context) {
    return showDialog<Section>(
      context: context,
      builder: (_) => const AddSectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Add a section'),
      children: [
        _Option(
          icon: Icons.list_alt_outlined,
          title: 'Regular',
          subtitle: 'Items with individual prices and allergens',
          onTap: () => Navigator.pop(
            context,
            RegularSection(name: 'New Section'),
          ),
        ),
        _Option(
          icon: Icons.star_outline,
          title: 'Special proposal',
          subtitle: 'Items at one shared price with a note',
          onTap: () => Navigator.pop(
            context,
            SpecialSelection(name: 'New Proposal'),
          ),
        ),
        _Option(
          icon: Icons.wine_bar_outlined,
          title: 'Wine list',
          subtitle: 'Wines and beverages with prices',
          onTap: () => Navigator.pop(
            context,
            WineSection(name: 'Vini'),
          ),
        ),
        _Option(
          icon: Icons.event_outlined,
          title: 'Event program',
          subtitle: 'Events or courses with optional times and prices',
          onTap: () => Navigator.pop(
            context,
            EventSection(name: 'Programme'),
          ),
        ),
        _Option(
          icon: Icons.article_outlined,
          title: 'Cover page',
          subtitle: 'Full-page intro with venue name and logo',
          onTap: () => Navigator.pop(
            context,
            CoverSection(),
          ),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
