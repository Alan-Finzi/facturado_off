
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../bloc/cubit_payment_methods/payment_methods_cubit.dart';
import '../bloc/cubit_productos/productos_cubit.dart';


class ResumenTabla extends StatelessWidget {
    const ResumenTabla({super.key});

    @override
    Widget build(BuildContext context) {
        return BlocBuilder<ProductosCubit, ProductosState>(
            builder: (context, productosState) {
                // Check if PaymentMethodsCubit is available in the context
                final PaymentMethodsCubit? paymentMethodsCubit =
                    _getPaymentMethodsCubit(context);

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

                // Calcular recargo según el método de pago seleccionado si está disponible
                double recargoRate = 0.0;
                double recargoAmount = 0.0;

                // Build UI with or without PaymentMethodsCubit based on availability
                Widget buildTableContent() {
                    // If PaymentMethodsCubit is available, use it to calculate recargo
                    if (paymentMethodsCubit != null) {
                        return BlocBuilder<PaymentMethodsCubit, PaymentMethodsState>(
                            builder: (context, paymentState) {
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

                                        // Obtener la tasa de recargo del método seleccionado
                                        recargoRate = selectedMethod.recargo;

                                        // Calcular el monto de recargo directamente desde el PaymentMethodsCubit
                                        // para asegurar consistencia entre el cálculo y lo que se muestra
                                        recargoAmount = paymentMethodsCubit.getRecargoAmount();
                                    }
                                }

                                // Calcular total final: subtotal - descuentos + IVA + recargo
                                final totalFinal = subtotal - descuentoGral + totalIva + recargoAmount;

                                // Actualizar el total en el PaymentMethodsCubit
                                // Siempre actualizamos el subtotal en el PaymentMethodsCubit para que se calcule el recargo
                                if (paymentState is PaymentMethodsLoaded && subtotal > 0) {
                                    // Calculamos el subtotal para recargo (subtotal - descuento + IVA)
                                    final subtotalParaRecargo = subtotal - descuentoGral + totalIva;

                                    // Forzar actualización inmediata para asegurar que el estado se actualice correctamente
                                    paymentMethodsCubit.updateSubtotalAmount(subtotalParaRecargo);

                                    // Si hay un método seleccionado, actualizar inmediatamente
                                    if (paymentState.selectedProviderId != null) {
                                        paymentMethodsCubit.selectPaymentProvider(paymentState.selectedProviderId!);
                                    }

                                    if (paymentState.selectedMethodId != null) {
                                        paymentMethodsCubit.selectPaymentMethod(paymentState.selectedMethodId!);
                                    }

                                    // Usar microtask para asegurar actualizaciones adicionales después de que el framework haya procesado el estado
                                    Future.microtask(() {
                                        // Actualizar nuevamente para asegurar que el recargo se calcule correctamente
                                        paymentMethodsCubit.updateSubtotalAmount(subtotalParaRecargo);

                                        // Forzar actualizaciones adicionales si hay un método seleccionado
                                        if (paymentState.selectedMethodId != null) {
                                            // Primero seleccionamos el proveedor si es necesario
                                            if (paymentState.selectedProviderId != null) {
                                                paymentMethodsCubit.selectPaymentProvider(paymentState.selectedProviderId!);
                                            }
                                            // Luego seleccionamos el método de pago para calcular el recargo
                                            paymentMethodsCubit.selectPaymentMethod(paymentState.selectedMethodId!);

                                            // Obtener recargo actualizado para depuración
                                            final updatedRecargoAmount = paymentMethodsCubit.getRecargoAmount();
                                            final updatedTotal = subtotalParaRecargo + updatedRecargoAmount;

                                            print('=== RESUMEN TABLA - Actualizaciones ===');
                                            print('Subtotal para recargo: \$${subtotalParaRecargo.toStringAsFixed(2)}');
                                            print('Recargo en ResumenTabla: \$${updatedRecargoAmount.toStringAsFixed(2)}');
                                            print('Total con recargo: \$${updatedTotal.toStringAsFixed(2)}');

                                            // Implementar una verificación adicional para asegurar la consistencia de estado
                                            Future.delayed(Duration(milliseconds: 100), () {
                                                // Esta actualización final garantiza que el recargo se ha calculado completamente
                                                paymentMethodsCubit.updateSubtotalAmount(subtotalParaRecargo);
                                                if (paymentState.selectedMethodId != null) {
                                                    paymentMethodsCubit.selectPaymentMethod(paymentState.selectedMethodId!);

                                                    // Verificar si hubo cambios significativos
                                                    final finalRecargoAmount = paymentMethodsCubit.getRecargoAmount();
                                                    if ((finalRecargoAmount - updatedRecargoAmount).abs() > 0.01) {
                                                        print('Detectada inconsistencia en recargo: ${finalRecargoAmount.toStringAsFixed(2)} vs ${updatedRecargoAmount.toStringAsFixed(2)}');
                                                    }
                                                }
                                                print('=== RESUMEN TABLA - Sincronización finalizada ===');
                                            });
                                        }
                                    });
                                }

                                return _buildTable(
                                    subtotal: subtotal,
                                    descuentoPromos: descuentoPromos,
                                    descuentoGral: descuentoGral,
                                    totalIva: totalIva,
                                    recargoRate: recargoRate,
                                    recargoAmount: recargoAmount,
                                    totalFinal: totalFinal,
                                    productosState: productosState,
                                );
                            }
                        );
                    }
                    // If PaymentMethodsCubit is not available, show the table without recargo
                    else {
                        // Calcular total final sin recargo: subtotal - descuentos + IVA
                        final totalFinal = subtotal - descuentoGral + totalIva;

                        return _buildTable(
                            subtotal: subtotal,
                            descuentoPromos: descuentoPromos,
                            descuentoGral: descuentoGral,
                            totalIva: totalIva,
                            recargoRate: recargoRate,
                            recargoAmount: recargoAmount,
                            totalFinal: totalFinal,
                            productosState: productosState,
                        );
                    }
                }

                return buildTableContent();
            },
        );
    }

    // Helper method to safely get PaymentMethodsCubit if available
    PaymentMethodsCubit? _getPaymentMethodsCubit(BuildContext context) {
        try {
            return context.read<PaymentMethodsCubit>();
        } catch (e) {
            // Provider not found, return null
            return null;
        }
    }

    // Helper method to build the table UI
    Widget _buildTable({
        required double subtotal,
        required double descuentoPromos,
        required double descuentoGral,
        required double totalIva,
        required double recargoRate,
        required double recargoAmount,
        required double totalFinal,
        required ProductosState productosState,
    }) {
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
                    // Siempre mostrar la fila de recargo, incluso cuando es cero
                    TableRow(
                        decoration: recargoAmount > 0 ? BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                        ) : null,
                        children: [
                            Padding(
                                padding: recargoAmount > 0 ? EdgeInsets.all(4.0) : EdgeInsets.zero,
                                child: Row(
                                    children: [
                                        if (recargoAmount > 0)
                                            Icon(Icons.payment, size: 12, color: Colors.red[700]),
                                        SizedBox(width: recargoAmount > 0 ? 4.0 : 0),
                                        Text(
                                            '+ Recargo (${recargoRate.toStringAsFixed(1)}%)',
                                            style: TextStyle(
                                                fontSize: recargoAmount > 0 ? 11 : 10,
                                                fontWeight: recargoAmount > 0 ? FontWeight.bold : FontWeight.normal,
                                                color: recargoAmount > 0 ? Colors.red[700] : Colors.grey
                                            ),
                                        ),
                                    ],
                                ),
                            ),
                            Padding(
                                padding: recargoAmount > 0 ? EdgeInsets.all(4.0) : EdgeInsets.zero,
                                child: Text(
                                    '+ \$${recargoAmount.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontWeight: recargoAmount > 0 ? FontWeight.bold : FontWeight.normal,
                                        color: recargoAmount > 0 ? Colors.red[700] : Colors.grey,
                                        fontSize: recargoAmount > 0 ? 12 : 10
                                    )
                                ),
                            ),
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
    }

    static String _porcentaje(double valor, double base) {
        if (base == 0) return '0';
        final porcentaje = (valor / base) * 100;
        return porcentaje.toStringAsFixed(1);
    }
}