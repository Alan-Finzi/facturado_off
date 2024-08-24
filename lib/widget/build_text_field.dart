import 'package:flutter/material.dart';
class CustomTextField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final int maxLength;
  final int maxLines;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final String initialValue;
  final bool readOnly;
  final VoidCallback? onTap;
  final void Function(dynamic value)? onChanged;

  const CustomTextField({
    required this.labelText,
    required this.hintText,
    this.maxLength = 0,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.validator,
    this.initialValue = '',
    this.readOnly = false,
    this.onTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLength: maxLength > 0 ? maxLength : null,
        maxLines: maxLines,
        keyboardType: keyboardType,
        readOnly: readOnly,
        initialValue: controller == null ? initialValue : null, // Evita el conflicto con el controlador
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          border: OutlineInputBorder(),
        ),
        validator: validator,
        onTap: onTap,
        onChanged: onChanged, // Añadido el campo onChanged
      ),
    );
  }
}
