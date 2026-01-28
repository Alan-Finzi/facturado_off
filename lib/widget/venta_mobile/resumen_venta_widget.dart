import 'package:flutter/material.dart';

/// Widget para mostrar el resumen de la venta con totales
class ResumenVentaWidget extends StatelessWidget {
  /// Subtotal de la venta
  final double subtotal;

  /// Monto de descuento
  final double descuento;

  /// Porcentaje de descuento
  final double porcentajeDescuento;

  /// Monto de recargo
  final double recargo;

  /// Porcentaje de recargo
  final double porcentajeRecargo;

  /// Monto de IVA
  final double iva;

  /// Total de la venta
  final double total;

  /// Deuda pendiente
  final double deuda;

  /// Formateador para los montos
  final String Function(double) formatearMonto;

  /// Texto para mostrar en el mensaje de retiro
  final String mensajeRetiro;

  const ResumenVentaWidget({
    super.key,
    required this.subtotal,
    required this.descuento,
    required this.iva,
    required this.total,
    required this.deuda,
    this.porcentajeDescuento = 0.0,
    this.recargo = 0.0,
    this.porcentajeRecargo = 0.0,
    this.mensajeRetiro = 'Retiro en el local',
    this.formatearMonto = _defaultFormatMonto,
  });

  static String _defaultFormatMonto(double monto) {
    return '\$ ${monto.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:', style: TextStyle(fontSize: 16)),
              Text(
                formatearMonto(subtotal),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Descuento
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Descuento${porcentajeDescuento > 0 ? ' (${porcentajeDescuento.toStringAsFixed(0)}%)' : ''}:',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                formatearMonto(descuento),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Recargo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recargo${porcentajeRecargo > 0 ? ' (${porcentajeRecargo.toStringAsFixed(0)}%)' : ' (0%)'}:',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                formatearMonto(recargo),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // IVA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('IVA:', style: TextStyle(fontSize: 16)),
              Text(
                formatearMonto(iva),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('(incluido en el precio)', style: TextStyle(fontSize: 14, color: Colors.grey)),

          const SizedBox(height: 8),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                formatearMonto(total),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          // Opción de retiro
          const SizedBox(height: 16),
          Text(
            mensajeRetiro,
            style: const TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}