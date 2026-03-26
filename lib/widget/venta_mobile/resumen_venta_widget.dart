import 'package:flutter/material.dart';

/// Widget para mostrar el resumen de la venta con totales
class ResumenVentaWidget extends StatelessWidget {
  /// Precio sin IVA (suma de precioLista * cantidad)
  final double subtotal;

  /// Monto de IVA
  final double iva;

  /// Monto de descuento general
  final double descuento;

  /// Porcentaje de descuento general
  final double porcentajeDescuento;

  /// Monto de descuento adicional (ingresado en el cobro)
  final double descuentoAdicional;

  /// Porcentaje de descuento adicional
  final double porcentajeDescuentoAdicional;

  /// Monto de recargo
  final double recargo;

  /// Porcentaje de recargo
  final double porcentajeRecargo;

  /// Total final de la venta
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
    required this.iva,
    required this.descuento,
    required this.total,
    required this.deuda,
    this.porcentajeDescuento = 0.0,
    this.descuentoAdicional = 0.0,
    this.porcentajeDescuentoAdicional = 0.0,
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
    final subtotalConIva = subtotal + iva;

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
          // ── Precio sin IVA ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Precio sin IVA:', style: TextStyle(fontSize: 15, color: Colors.black54)),
              Text(formatearMonto(subtotal),
                  style: const TextStyle(fontSize: 15, color: Colors.black54)),
            ],
          ),

          const SizedBox(height: 4),

          // ── IVA ─────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('+ IVA (incluido en precios):', style: TextStyle(fontSize: 15, color: Colors.black54)),
              Text(formatearMonto(iva),
                  style: const TextStyle(fontSize: 15, color: Colors.black54)),
            ],
          ),

          const Divider(height: 16),

          // ── Subtotal con IVA ────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal c/IVA:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text(formatearMonto(subtotalConIva),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),

          const SizedBox(height: 8),

          // ── Descuento general ───────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '- Descuento${porcentajeDescuento > 0 ? ' (${porcentajeDescuento.toStringAsFixed(0)}%)' : ''}:',
                style: const TextStyle(fontSize: 15),
              ),
              Text(formatearMonto(descuento),
                  style: const TextStyle(fontSize: 15)),
            ],
          ),

          // ── Descuento adicional (solo si > 0) ───────────────────
          if (descuentoAdicional > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '- Desc. adicional (${porcentajeDescuentoAdicional.toStringAsFixed(1)}%):',
                  style: const TextStyle(fontSize: 15, color: Colors.green),
                ),
                Text(formatearMonto(descuentoAdicional),
                    style: const TextStyle(fontSize: 15, color: Colors.green)),
              ],
            ),
          ],

          const SizedBox(height: 4),

          // ── Recargo ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '+ Recargo${porcentajeRecargo > 0 ? ' (${porcentajeRecargo.toStringAsFixed(1)}%)' : ' (0%)'}:',
                style: const TextStyle(fontSize: 15),
              ),
              Text(formatearMonto(recargo),
                  style: const TextStyle(fontSize: 15)),
            ],
          ),

          const Divider(height: 16),

          // ── TOTAL ───────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(formatearMonto(total),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),

          // ── Mensaje de retiro ───────────────────────────────────
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
