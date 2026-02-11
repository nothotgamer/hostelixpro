import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class CustomTextField extends StatelessWidget {
  final String name;
  final String label;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final String? hint;

  final bool isPassword;
  final List<String? Function(String?)>? validators;

  const CustomTextField({
    super.key,
    required this.name,
    required this.label,
    this.prefixIcon,
    this.isPassword = false,
    this.validators,
    this.keyboardType,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: name,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      obscureText: isPassword,
      validator: validators != null ? (value) {
        for (final validator in validators!) {
          final error = validator(value);
          if (error != null) return error;
        }
        return null;
      } : null,
    );
  }
}
