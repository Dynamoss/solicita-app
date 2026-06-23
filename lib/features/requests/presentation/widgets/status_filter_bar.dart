import 'package:flutter/material.dart';

import '../../domain/entities/request_status.dart';
import 'status_chip.dart';

/// Horizontal, reactive status filter. `null` selection = "Todos".
class StatusFilterBar extends StatelessWidget {
  const StatusFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final RequestStatus? selected;
  final ValueChanged<RequestStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterChip(
            label: 'Todos',
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final status in RequestStatus.values)
            _FilterChip(
              label: status.label,
              color: StatusVisuals.color(status),
              selected: selected == status,
              onTap: () => onChanged(status),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        labelStyle: TextStyle(
          color: selected ? accent : scheme.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        selectedColor: accent.withValues(alpha: 0.14),
        side: BorderSide(
          color: selected ? accent : Colors.transparent,
          width: 1.2,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
