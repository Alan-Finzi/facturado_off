import 'package:flutter/material.dart';

/// Widget para mostrar los datos básicos de venta (título y número de factura)
class DatosVentaWidget extends StatelessWidget {
  /// Título de la venta
  final String titulo;

  /// Prefijo del número de factura
  final String? prefijo;

  /// Número de factura
  final String? numeroFactura;

  /// Tipo de factura seleccionado
  final String tipoFactura;

  /// Callback cuando cambia el tipo de factura
  final void Function(String?)? onTipoFacturaChanged;

  /// Lista de tipos de factura disponibles
  final List<String> tiposFactura;

  const DatosVentaWidget({
    super.key,
    required this.titulo,
    this.prefijo,
    this.numeroFactura,
    required this.tipoFactura,
    this.onTipoFacturaChanged,
    this.tiposFactura = const ['Factura A', 'Factura B', 'Factura C'],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título y número de factura
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (prefijo != null || numeroFactura != null)
              Row(
                children: [
                  if (prefijo != null)
                    Text(
                      '$prefijo - ',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  if (numeroFactura != null)
                    Text(
                      numeroFactura!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Panel de factura
        Container(
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
              value: tipoFactura,
              icon: const Icon(Icons.keyboard_arrow_down),
              onChanged: onTipoFacturaChanged,
              items: tiposFactura
                  .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}