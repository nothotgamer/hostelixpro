import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:hostelixpro/models/user.dart';
import 'package:hostelixpro/services/user_service.dart';
import 'package:hostelixpro/widgets/common/custom_text_field.dart';

class UserApprovalDialog extends StatefulWidget {
  final User user;
  final VoidCallback onSuccess;

  const UserApprovalDialog({
    super.key,
    required this.user,
    required this.onSuccess,
  });

  @override
  State<UserApprovalDialog> createState() => _UserApprovalDialogState();
}

class _UserApprovalDialogState extends State<UserApprovalDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  List<User> _teachers = [];
  bool _isLoadingTeachers = true;

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
  }

  Future<void> _fetchTeachers() async {
    try {
      final teachers = await UserService.getUsers(role: 'teacher');
      if (mounted) {
        setState(() {
          _teachers = teachers;
          _isLoadingTeachers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTeachers = false);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to load teachers: $e')),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isLoading = true);
      
      final formData = _formKey.currentState!.value;
      
      try {
        await UserService.approveUser(
          userId: widget.user.id,
          admissionNo: formData['admission_no'],
          room: formData['room'],
          assignedTeacherId: formData['assigned_teacher_id'],
          monthlyFeeAmount: formData['monthly_fee_amount'] != null ? double.tryParse(formData['monthly_fee_amount']) : null,
        );
        
        if (mounted) {
          Navigator.pop(context); // Close dialog
          widget.onSuccess(); // Refresh parent list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User approved successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Approve ${widget.user.displayName ?? widget.user.email}'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400, // Fixed width for desktop
          child: FormBuilder(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Assign details to activate this student account.'),
                const SizedBox(height: 24),
                
                CustomTextField(
                  name: 'admission_no',
                  label: 'Admission Number',
                  validators: [FormBuilderValidators.required()],
                ),
                const SizedBox(height: 16),
                
                CustomTextField(
                  name: 'room',
                  label: 'Room Number',
                  validators: [FormBuilderValidators.required()],
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  name: 'monthly_fee_amount',
                  label: 'Monthly Fee Amount (Optional)',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                
                // Teacher Dropdown
                _isLoadingTeachers
                    ? const Center(child: CircularProgressIndicator())
                    : FormBuilderDropdown<int>(
                        name: 'assigned_teacher_id',
                        decoration: const InputDecoration(
                          labelText: 'Assign Teacher',
                          border: OutlineInputBorder(),
                          filled: true,
                        ),
                        validator: FormBuilderValidators.required(),
                        items: _teachers
                            .map((t) => DropdownMenuItem(
                                  value: t.id,
                                  child: Text(t.displayName ?? t.email),
                                ))
                            .toList(),
                      ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Approve & Assign'),
        ),
      ],
    );
  }
}
