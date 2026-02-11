import 'package:flutter/material.dart';
import 'package:hostelixpro/theme/typography.dart';


class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final String? title;
  final List<Widget>? actions;

  const AppHeader({
    super.key,
    this.onMenuPressed,
    this.title,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    // Use theme colors for dark mode support
    final colorScheme = Theme.of(context).colorScheme;
    final surfaceColor = colorScheme.surface;
    final borderColor = colorScheme.outlineVariant;
    final textPrimary = colorScheme.onSurface;

    return Container(
      height: 72,
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor.withValues(alpha: 0.5))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Mobile menu button
          if (onMenuPressed != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: onMenuPressed,
                tooltip: 'Menu',
              ),
            ),
          
          if (title != null) ...[
            Flexible(
              child: Text(
                title!,
                style: AppTypography.h3.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
            
          const Spacer(),
          
          if (actions != null) 
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...actions!,
                    const SizedBox(width: 24),
                  ],
                ),
              ),
            ),
          

          
          const SizedBox(width: 8), // Right padding
        ],
      ),
    );
  }
}
