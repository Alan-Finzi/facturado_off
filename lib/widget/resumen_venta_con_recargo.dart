import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_productos/productos_cubit.dart';

/// Widget para mostrar el resumen de venta con recargos
/// Incluye soporte para pagos divididos con diferentes recargos
class ResumenVentaConRecargo extends StatelessWidget {
  const ResumenVentaConRecargo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductosCubit, ProductosState>(
      builder: (context, state) {
        // Obtener productos seleccionados
        final productos = state.productosSeleccionados;

        // Calcular subtotal, IVA y total sin recargo
        double subtotal = 0;
        double totalIva = 0;
        double totalSinRecargo = 0;

        for (var producto in productos) {
          final precioLista = producto.precioLista ?? 0;
          final cantidad = producto.cantidad ?? 1;
          final precioFinal = producto.precioFinal ?? 0;

          subtotal += precioLista * cantidad;
          totalSinRecargo += precioFinal;
          totalIva += (precioFinal - (precioLista * cantidad));
        }

        // Calcular descuentos
        const descuentoPromos = 0.0;
        final descuentoGral = (state.descuentoGeneral / 100) * subtotal;
        final subtotalConDescuento = subtotal - descuentoGral;

        // Calcular recargo según el modo de pago
        double recargo = 0.0;
        double porcentajeRecargo = 0.0;

        if (state.esPagoDividido) {
          // Para pagos divididos, usar el total de recargos de cada pago parcial
          recargo = state.pagosParciales.fold(
            0, (sum, pago) => sum + pago.montoRecargo
          );

          // Calcular el porcentaje efectivo
          if (subtotalConDescuento > 0) {
            porcentajeRecargo = (recargo / subtotalConDescuento) * 100;
          }
        } else {
          // Para pago único, usar el recargo general
          porcentajeRecargo = state.recargoPago;
          recargo = (porcentajeRecargo / 100) * subtotalConDescuento;
        }

        // Calcular total final con recargo
        final totalFinal = totalSinRecargo - descuentoGral + recargo;

        // Mostrar el resumen en una tabla
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen de venta',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    children: [
                      const Text('SUBTOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('\$${subtotal.toStringAsFixed(2)}', textAlign: TextAlign.right),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Text('- Descuento promociones', style: TextStyle(fontSize: 10)),
                      Text('- \$${descuentoPromos.toStringAsFixed(2)}', textAlign: TextAlign.right),
                    ],
                  ),
                  TableRow(
                    children: [
                      Text('- Descuento Gral (${state.descuentoGeneral.round()}%)',
                        style: const TextStyle(fontSize: 10)),
                      Text('- \$${descuentoGral.toStringAsFixed(2)}', textAlign: TextAlign.right),
                    ],
                  ),
                  TableRow(
                    children: [
                      Text(
                        state.esPagoDividido
                          ? '+ Recargo pagos (${porcentajeRecargo.toStringAsFixed(1)}% efectivo)'
                          : '+ Recargo (${porcentajeRecargo.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 10,
                          color: recargo > 0 ? Colors.red : Colors.grey
                        )
                      ),
                      Text(
                        '+ \$${recargo.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: recargo > 0 ? Colors.red : Colors.grey
                        )
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Text('+ IVA'),
                      Text('+ \$${totalIva.toStringAsFixed(2)}', textAlign: TextAlign.right),
                    ],
                  ),
                  const TableRow(
                    children: [
                      SizedBox(height: 8.0),
                      SizedBox(height: 8.0),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('\$${totalFinal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.right
                      ),
                    ],
                  ),
                ],
              ),

              // Si es pago dividido, mostrar información adicional
              if (state.esPagoDividido && state.pagosParciales.isNotEmpty)
                _buildPagoDivididoInfo(state),
            ],
          ),
        );
      },
    );
  }

  /// Construye un widget que muestra información de pagos parciales
  Widget _buildPagoDivididoInfo(ProductosState state) {
    // Calcular el total pagado
    final totalPagado = state.pagosParciales.fold(
      0.0, (sum, pago) => sum + pago.montoTotal
    );

    // Calcular el total de la venta
    double totalVenta = 0.0;
    for (var producto in state.productosSeleccionados) {
      totalVenta += producto.precioFinal ?? 0;
    }

    // Aplicar descuento general
    totalVenta = totalVenta - ((state.descuentoGeneral / 100) * totalVenta);

    // Calcular saldo
    final saldo = totalVenta - totalPagado;

    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalle de pagos',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total pagado:'),
              Text('\$${totalPagado.toStringAsFixed(2)}'),
            ],
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(saldo > 0 ? 'Saldo pendiente:' : 'Vuelto:'),
              Text(
                '\$${saldo.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  color: saldo > 0 ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}