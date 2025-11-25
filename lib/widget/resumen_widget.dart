
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_payment_methods/payment_methods_cubit.dart';
import '../bloc/cubit_productos/productos_cubit.dart';


class ResumenTabla extends StatelessWidget {
    const ResumenTabla({super.key});

    @override
    Widget build(BuildContext context) {
        return BlocBuilder<ProductosCubit, ProductosState>(
            builder: (context, productosState) {
                return BlocBuilder<PaymentMethodsCubit, PaymentMethodsState>(
                    builder: (context, paymentState) {
                        final productos = productosState.productosSeleccionados;

                        double subtotal = 0;
                        double totalIva = 0;
                        double subtotalConIva = 0;

                        for (var producto in productos) {
                            final precioLista = producto.precioLista ?? 0;
                            final cantidad = producto.cantidad ?? 1;
                            final precioFinal = producto.precioFinal ?? 0;

                            subtotal += precioLista * cantidad;
                            subtotalConIva += precioFinal;
                            totalIva += (precioFinal - (precioLista * cantidad));
                        }

                        // Utilizar el descuento general del estado
                        const descuentoPromos = 0.0;
                        final descuentoGral = (productosState.descuentoGeneral / 100) * subtotal;

                        // Calcular recargo según el método de pago seleccionado
                        double recargoRate = 0.0;
                        double recargoAmount = 0.0;

                        if (paymentState is PaymentMethodsLoaded &&
                            paymentState.selectedProviderId != null &&
                            paymentState.selectedMethodId != null) {

                            final selectedProvider = paymentState.providers.firstWhere(
                                (p) => p.id == paymentState.selectedProviderId,
                                orElse: () => throw Exception('Proveedor no encontrado'),
                            );

                            if (selectedProvider.metodosPago != null) {
                                final selectedMethod = selectedProvider.metodosPago!.firstWhere(
                                    (m) => m.id == paymentState.selectedMethodId,
                                    orElse: () => throw Exception('Método no encontrado'),
                                );

                                recargoRate = selectedMethod.recargo;
                                recargoAmount = (subtotal - descuentoGral + totalIva) * (recargoRate / 100);
                            }
                        }

                        // Calcular total final: subtotal - descuentos + IVA + recargo
                        final totalFinal = subtotal - descuentoGral + totalIva + recargoAmount;

                        // Actualizar el total en el PaymentMethodsCubit
                        if (paymentState is PaymentMethodsLoaded &&
                            subtotal > 0 && subtotal != paymentState.subtotalAmount) {
                            Future.microtask(() {
                                context.read<PaymentMethodsCubit>().updateSubtotalAmount(
                                    subtotal - descuentoGral + totalIva
                                );
                            });
                        }

                        return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Table(
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
                                            Text('- Descuento Gral (${productosState.descuentoGeneral.round()}%)', style: const TextStyle(fontSize: 10)),
                                            Text('- \$${descuentoGral.toStringAsFixed(2)}', textAlign: TextAlign.right),
                                        ],
                                    ),
                                    TableRow(
                                        children: [
                                            const Text('+ IVA'),
                                            Text('+ \$${totalIva.toStringAsFixed(2)}', textAlign: TextAlign.right),
                                        ],
                                    ),
                                    TableRow(
                                        children: [
                                            Text('+ Recargo (${recargoRate.toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 10)),
                                            Text('+ \$${recargoAmount.toStringAsFixed(2)}', textAlign: TextAlign.right),
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
                                            Text('\$${totalFinal.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                    ),
                                ],
                            ),
                        );
                    },
                );
            },
        );
    }

    static String _porcentaje(double valor, double base) {
        if (base == 0) return '0';
        final porcentaje = (valor / base) * 100;
        return porcentaje.toStringAsFixed(1);
    }
}