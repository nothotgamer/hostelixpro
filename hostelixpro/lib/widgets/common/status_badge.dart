import 'package:flutter/material.dart';
import 'package:hostelixpro/theme/colors.dart';
import 'package:hostelixpro/theme/typography.dart';

enum StatusType { approved, pending, rejected, info, warning }

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType type;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusType.info,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;

    switch (type) {
      case StatusType.approved:
        color = AppColors.success;
        bg = AppColors.success.withValues(alpha: 0.1);
        break;
      case StatusType.pending:
      case StatusType.warning:
        color = AppColors.warning;
        bg = AppColors.warning.withValues(alpha: 0.1);
        break;
      case StatusType.rejected:
        color = AppColors.danger;
        bg = AppColors.danger.withValues(alpha: 0.1);
        break;
      case StatusType.info:
        color = AppColors.info;
        bg = AppColors.info.withValues(alpha: 0.1);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: AppTypography.label.copyWith(
              color: color, 
              fontSize: 10, 
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }
}
