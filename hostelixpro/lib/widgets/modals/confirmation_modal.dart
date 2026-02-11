import 'package:flutter/material.dart';
import 'package:hostelixpro/theme/colors.dart';
import 'package:hostelixpro/theme/typography.dart';
import 'package:hostelixpro/widgets/forms/form_field.dart';

class ConfirmationModal extends StatefulWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final bool requireReason;
  final Future<void> Function(String? reason) onConfirm;

  const ConfirmationModal({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.requireReason = false,
  });

  @override
  State<ConfirmationModal> createState() => _ConfirmationModalState();
}

class _ConfirmationModalState extends State<ConfirmationModal> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _handleConfirm() async {
    if (widget.requireReason) {
      if (!_formKey.currentState!.validate()) return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onConfirm(widget.requireReason ? _reasonController.text : null);
      if (mounted) Navigator.of(context).pop(true); // Return true on success
    } catch (e) {
      // Error handling should be done by caller or global toast, but stop loading here
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.isDestructive ? Icons.warning_amber : Icons.info_outline,
                      color: widget.isDestructive ? AppColors.danger : AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(widget.title, style: AppTypography.h3),
                  ],
                ),
                const SizedBox(height: 16),
                Text(widget.message, style: AppTypography.body),
                
                if (widget.requireReason) ...[
                  const SizedBox(height: 24),
                  AppFormField(
                    label: 'Reason for action',
                    controller: _reasonController,
                    maxLines: 2,
                    validator: (val) => val == null || val.isEmpty ? 'Reason is required' : null,
                    hint: 'Enter justification...',
                  ),
                ],

                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                      child: Text(widget.cancelLabel),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isDestructive ? AppColors.danger : AppColors.primary,
                      ),
                      child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(widget.confirmLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
