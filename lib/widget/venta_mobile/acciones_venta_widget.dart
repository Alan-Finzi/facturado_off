import 'package:flutter/material.dart';

/// Widget para los botones de acción en la página de venta
class AccionesVentaWidget extends StatelessWidget {
  /// Callback para el botón de cancelar
  final VoidCallback? onCancelar;

  /// Callback para el botón de guardar
  final VoidCallback? onGuardar;

  /// Deuda pendiente a mostrar
  final double deuda;

  /// Formateador para la deuda
  final String Function(double) formatearDeuda;

  /// Texto para el botón de cancelar
  final String textoCancelar;

  /// Texto para el botón de guardar
  final String textoGuardar;

  const AccionesVentaWidget({
    super.key,
    this.onCancelar,
    this.onGuardar,
    required this.deuda,
    this.formatearDeuda = _defaultFormatDeuda,
    this.textoCancelar = 'Cancelar',
    this.textoGuardar = 'Guardar',
  });

  static String _defaultFormatDeuda(double deuda) {
    return '\$ ${deuda.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Botón de Cancelar
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: onCancelar,
                  child: Text(textoCancelar, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Botón de Guardar
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: onGuardar,
                  child: Text(textoGuardar, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Deuda
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Deuda:', style: TextStyle(fontSize: 16)),
            Text(
              formatearDeuda(deuda),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}