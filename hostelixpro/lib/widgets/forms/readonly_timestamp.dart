import 'package:flutter/material.dart';
import 'package:hostelixpro/theme/colors.dart';
import 'package:hostelixpro/theme/typography.dart';
import 'package:intl/intl.dart';

class ReadOnlyTimestamp extends StatelessWidget {
  final String label;
  final int? timestampMs; 
  
  const ReadOnlyTimestamp({
    super.key,
    required this.label,
    this.timestampMs,
  });

  @override
  Widget build(BuildContext context) {
    final displayTime = timestampMs != null 
        ? DateFormat('MMM d, yyyy - h:mm a').format(DateTime.fromMillisecondsSinceEpoch(timestampMs!))
        : 'Set by server on submit';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(
                displayTime,
                style: AppTypography.bodySmall.copyWith(
                  color: timestampMs != null ? AppColors.textPrimary : AppColors.textSecondary,
                  fontStyle: timestampMs == null ? FontStyle.italic : FontStyle.normal,
                ),
              ),
              if (timestampMs == null) ...[
                const Spacer(),
                const Tooltip(
                  message: "Server Authority: Time is set by the server to ensure audit integrity.",
                  child: Icon(Icons.lock_outline, size: 14, color: AppColors.textSecondary),
                )
              ]
            ],
          ),
        ),
      ],
    );
  }
}
