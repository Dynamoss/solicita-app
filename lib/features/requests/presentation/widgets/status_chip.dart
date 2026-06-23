import 'package:flutter/material.dart';

import '../../domain/entities/request_status.dart';

/// Semantic colors for each status. Defined once and reused by the chip and the
/// status picker so the visual language stays consistent.
abstract final class StatusVisuals {
  static Color color(RequestStatus status) => switch (status) {
        RequestStatus.open => const Color(0xFF1E88E5),
        RequestStatus.inProgress => const Color(0xFFF59E0B),
        RequestStatus.resolved => const Color(0xFF2E9E5B),
        RequestStatus.cancelled => const Color(0xFF9AA0A6),
      };

  static IconData icon(RequestStatus status) => switch (status) {
        RequestStatus.open => Icons.fiber_new_rounded,
        RequestStatus.inProgress => Icons.autorenew_rounded,
        RequestStatus.resolved => Icons.check_circle_rounded,
        RequestStatus.cancelled => Icons.cancel_rounded,
      };
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.compact = false});

  final RequestStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = StatusVisuals.color(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(StatusVisuals.icon(status), size: compact ? 13 : 15, color: color),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 11 : 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class PriorityChip extends StatelessWidget {
  const PriorityChip({super.key, required this.priority});

  final RequestPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      RequestPriority.high => const Color(0xFFE53935),
      RequestPriority.medium => const Color(0xFFF59E0B),
      RequestPriority.low => const Color(0xFF6B7280),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flag_rounded, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          priority.label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
