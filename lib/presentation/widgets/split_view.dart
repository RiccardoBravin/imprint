import 'package:flutter/material.dart';

/// A horizontally resizable two-pane split view.
///
/// The user drags the divider to adjust the split. The fraction is clamped to
/// [[minFraction], [maxFraction]].
class SplitView extends StatefulWidget {
  const SplitView({
    super.key,
    required this.left,
    required this.right,
    this.initialFraction = 0.5,
    this.minFraction = 0.2,
    this.maxFraction = 0.8,
    this.dividerWidth = 6,
  });

  final Widget left;
  final Widget right;
  final double initialFraction;
  final double minFraction;
  final double maxFraction;
  final double dividerWidth;

  @override
  State<SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView> {
  late double _fraction;

  @override
  void initState() {
    super.initState();
    _fraction = widget.initialFraction;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final leftWidth =
            (totalWidth * _fraction - widget.dividerWidth / 2).clamp(0.0, totalWidth);
        final rightWidth =
            (totalWidth * (1 - _fraction) - widget.dividerWidth / 2).clamp(0.0, totalWidth);

        return Row(
          children: [
            SizedBox(width: leftWidth, child: widget.left),
            _Divider(
              width: widget.dividerWidth,
              onDragUpdate: (delta) {
                setState(() {
                  _fraction = (_fraction + delta / totalWidth).clamp(
                    widget.minFraction,
                    widget.maxFraction,
                  );
                });
              },
            ),
            SizedBox(width: rightWidth, child: widget.right),
          ],
        );
      },
    );
  }
}

class _Divider extends StatefulWidget {
  const _Divider({required this.width, required this.onDragUpdate});

  final double width;
  final ValueChanged<double> onDragUpdate;

  @override
  State<_Divider> createState() => _DividerState();
}

class _DividerState extends State<_Divider> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = _hovered
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
        : Theme.of(context).colorScheme.outlineVariant;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (d) => widget.onDragUpdate(d.delta.dx),
        child: SizedBox(
          width: widget.width,
          child: Center(
            child: Container(
              width: 1,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
