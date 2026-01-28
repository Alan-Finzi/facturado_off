import 'package:flutter/material.dart';

/// Widget reutilizable para campos de búsqueda con botón adicional
class BuscadorWidget extends StatelessWidget {
  /// Contenido principal del buscador (SearchField, TextField, etc.)
  final Widget child;

  /// Callback para el botón adicional
  final VoidCallback? onButtonPressed;

  /// Icono para el botón adicional
  final IconData buttonIcon;

  const BuscadorWidget({
    super.key,
    required this.child,
    this.onButtonPressed,
    this.buttonIcon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey[300]!),
              color: Colors.white,
            ),
            child: child,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[300]!),
            color: Colors.white,
          ),
          child: IconButton(
            icon: Icon(buttonIcon),
            onPressed: onButtonPressed,
          ),
        ),
      ],
    );
  }
}