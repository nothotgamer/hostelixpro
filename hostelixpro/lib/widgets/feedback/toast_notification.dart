import 'package:flutter/material.dart';
import 'package:hostelixpro/theme/colors.dart';

class AppToast {
  static void show(BuildContext context, String message, {bool isError = false}) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: isError ? const Duration(seconds: 5) : const Duration(seconds: 3),
        action: isError 
            ? SnackBarAction(label: 'DISMISS', textColor: Colors.white, onPressed: () {}) 
            : null,
      ),
    );
  }
}
