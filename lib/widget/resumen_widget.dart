
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
                    // Calculate basic totals that don't depend on payment method
                    double totalFinal = subtotal - descuentoGral + totalIva + recargoAmount;

                    if (paymentMethodsCubit != null) {
                        // If PaymentMethodsCubit is available, use it to calculate recargo
                        return BlocBuilder<PaymentMethodsCubit, PaymentMethodsState>(
                            builder: (context, paymentState) {
                                // Safe way to handle different payment states
                                if (paymentState is PaymentMethodsLoaded) {
                                    final loadedState = paymentState;

                                    // Calculate the subtotal for recargo
                                    final subtotalParaRecargo = subtotal - descuentoGral + totalIva;

                                    // Update provider and method if available
                                    if (loadedState.selectedProviderId != null &&
                                        loadedState.selectedMethodId != null) {

                                        try {
                                            final selectedProvider = loadedState.providers.firstWhere(
                                                (p) => p.id == loadedState.selectedProviderId,
                                                orElse: () => throw Exception('Proveedor no encontrado'),
                                            );

                                            if (selectedProvider.metodosPago != null) {
                                                final selectedMethod = selectedProvider.metodosPago!.firstWhere(
                                                    (m) => m.id == loadedState.selectedMethodId,
                                                    orElse: () => throw Exception('Método no encontrado'),
                                                );

                                                // Set recargo rate and amount
                                                recargoRate = selectedMethod.recargo;
                                                recargoAmount = paymentMethodsCubit.getRecargoAmount();
                                            }
                                        } catch (e) {
                                            print('Error al buscar método de pago: $e');
                                        }
                                    }

                                    // Update state if needed
                                    if (subtotal > 0) {
                                        // Paso 1: Actualizar el subtotal en el cubit
                                        paymentMethodsCubit.updateSubtotalAmount(subtotalParaRecargo);

                                        // Paso 2: Si hay un método seleccionado, forzar actualización
                                        if (loadedState.selectedProviderId != null) {
                                            paymentMethodsCubit.selectPaymentProvider(loadedState.selectedProviderId!);
                                        }

                                        if (loadedState.selectedMethodId != null) {
                                            paymentMethodsCubit.selectPaymentMethod(loadedState.selectedMethodId!);

                                            // Verify recargo calculation
                                            final calculatedRecargoAmount = paymentMethodsCubit.getRecargoAmount();
                                            if ((calculatedRecargoAmount - recargoAmount).abs() > 0.01) {
                                                recargoAmount = calculatedRecargoAmount;
                                                print('ResumenTabla: Recargo actualizado a ${recargoAmount.toStringAsFixed(2)}');
                                            }
                                        }

                                        // Microtask for secondary updates
                                        Future.microtask(() {
                                            paymentMethodsCubit.updateSubtotalAmount(subtotalParaRecargo);

                                            if (loadedState.selectedMethodId != null) {
                                                if (loadedState.selectedProviderId != null) {
                                                    paymentMethodsCubit.selectPaymentProvider(loadedState.selectedProviderId!);
                                                }

                                                paymentMethodsCubit.selectPaymentMethod(loadedState.selectedMethodId!);

                                                // Debug logging
                                                final updatedRecargoAmount = paymentMethodsCubit.getRecargoAmount();
                                                final updatedTotal = subtotalParaRecargo + updatedRecargoAmount;

                                                print('=== RESUMEN TABLA - Actualizaciones ===');
                                                print('Subtotal para recargo: \$${subtotalParaRecargo.toStringAsFixed(2)}');
                                                print('Recargo en ResumenTabla: \$${updatedRecargoAmount.toStringAsFixed(2)}');
                                                print('Total con recargo: \$${updatedTotal.toStringAsFixed(2)}');
                                            }
                                        });
                                    }

                                    // Calculate final total with recargo
                                    totalFinal = subtotal - descuentoGral + totalIva + recargoAmount;
                                }

                                // Return the built table with current values
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
                    } else {
                        // If PaymentMethodsCubit is not available, show table without recargo
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
                                        RichText(
                                            text: TextSpan(
                                                children: [
                                                    TextSpan(
                                                        text: '+ Recargo ',
                                                        style: TextStyle(
                                                            fontSize: recargoAmount > 0 ? 11 : 10,
                                                            fontWeight: recargoAmount > 0 ? FontWeight.bold : FontWeight.normal,
                                                            color: recargoAmount > 0 ? Colors.red[700] : Colors.grey
                                                        ),
                                                    ),
                                                    TextSpan(
                                                        text: '(${recargoRate.toStringAsFixed(1)}%)',
                                                        style: TextStyle(
                                                            fontSize: recargoAmount > 0 ? 11 : 10,
                                                            fontWeight: recargoAmount > 0 ? FontWeight.bold : FontWeight.normal,
                                                            color: recargoAmount > 0 ? Colors.red[900] : Colors.grey,
                                                            backgroundColor: recargoAmount > 0 ? Colors.yellow[100] : null,
                                                        ),
                                                    ),
                                                ],
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.black,
                                                ),
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