import 'package:flutter/material.dart';

/// Widget para seleccionar el tipo de entrega
class SelectorEntregaWidget extends StatelessWidget {
  /// Valor seleccionado actualmente
  final String value;

  /// Callback cuando cambia la selección
  final void Function(String?)? onChanged;

  /// Lista de opciones disponibles
  final List<String> opciones;

  const SelectorEntregaWidget({
    super.key,
    required this.value,
    this.onChanged,
    this.opciones = const ['Entregado', 'Envío', 'Retiro'],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down),
          onChanged: onChanged,
          items: opciones
              .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}