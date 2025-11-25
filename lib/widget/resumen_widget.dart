
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../bloc/cubit_payment_methods/payment_methods_cubit.dart';
import '../bloc/cubit_productos/productos_cubit.dart';


class ResumenTabla extends StatefulWidget {
    const ResumenTabla({super.key});

    @override
    _ResumenTablaState createState() => _ResumenTablaState();
}

class _ResumenTablaState extends State<ResumenTabla> {
    // Store recargo information to persist between builds
    double _recargoRate = 0.0;
    double _recargoAmount = 0.0;

    @override
    void initState() {
        super.initState();
        // Initialize with a post-frame callback to ensure proper context
        WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateRecargoFromPaymentMethod();
        });
    }

    // This method will force update the recargo information from the payment method
    void _updateRecargoFromPaymentMethod() {
        final PaymentMethodsCubit? paymentMethodsCubit = _getPaymentMethodsCubit(context);
        if (paymentMethodsCubit != null && paymentMethodsCubit.state is PaymentMethodsLoaded) {
            final loadedState = paymentMethodsCubit.state as PaymentMethodsLoaded;

            // Only calculate if we have a selected method
            if (loadedState.selectedMethodId != null &&
                loadedState.selectedProviderId != null &&
                loadedState.subtotalAmount > 0) {

                // Get the recargo amount from the cubit
                final calculatedRecargoAmount = paymentMethodsCubit.getRecargoAmount();

                // Update the stored values
                if (mounted) {
                    setState(() {
                        _recargoAmount = calculatedRecargoAmount;

                        // Try to get the recargo rate from the selected method
                        try {
                            final selectedProvider = loadedState.providers.firstWhere(
                                (p) => p.id == loadedState.selectedProviderId,
                            );

                            if (selectedProvider.metodosPago != null) {
                                final selectedMethod = selectedProvider.metodosPago!.firstWhere(
                                    (m) => m.id == loadedState.selectedMethodId,
                                );
                                _recargoRate = selectedMethod.recargo;
                            }
                        } catch (e) {
                            print('Error getting recargo rate: $e');
                        }
                    });
                }

                print('ResumenTabla: _updateRecargoFromPaymentMethod - Recargo updated to ${_recargoAmount.toStringAsFixed(2)} (${_recargoRate.toStringAsFixed(1)}%)');
            }
        }
    }

    @override
    Widget build(BuildContext context) {
        return BlocBuilder<ProductosCubit, ProductosState>(
            builder: (context, productosState) {
                // Check if PaymentMethodsCubit is available in the context
                final PaymentMethodsCubit? paymentMethodsCubit = _getPaymentMethodsCubit(context);

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

                // Calculate the subtotal for recargo (used to update PaymentMethodsCubit)
                final subtotalParaRecargo = subtotal - descuentoGral + totalIva;

                // Calculate final total with recargo
                final totalFinal = subtotal - descuentoGral + totalIva + _recargoAmount;

                // Build UI with or without PaymentMethodsCubit based on availability
                Widget buildTableContent() {
                    if (paymentMethodsCubit != null) {
                        // Update the subtotal in the PaymentMethodsCubit to ensure proper recargo calculation
                        if (subtotal > 0) {
                            paymentMethodsCubit.updateSubtotalAmount(subtotalParaRecargo);

                            // Add a listener to update recargo when payment state changes
                            return BlocListener<PaymentMethodsCubit, PaymentMethodsState>(
                                listener: (context, paymentState) {
                                    if (paymentState is PaymentMethodsLoaded) {
                                        // Update the recargo information when payment method changes
                                        _updateRecargoFromPaymentMethod();
                                    }
                                },
                                // Use BlocBuilder to rebuild when payment state changes
                                child: BlocBuilder<PaymentMethodsCubit, PaymentMethodsState>(
                                    builder: (context, paymentState) {
                                        // We always return the table with current values
                                        return _buildTable(
                                            subtotal: subtotal,
                                            descuentoPromos: descuentoPromos,
                                            descuentoGral: descuentoGral,
                                            totalIva: totalIva,
                                            recargoRate: _recargoRate,
                                            recargoAmount: _recargoAmount,
                                            totalFinal: totalFinal,
                                            productosState: productosState,
                                        );
                                    }
                                ),
                            );
                        } else {
                            // If subtotal is 0, just show the table without recargo
                            return _buildTable(
                                subtotal: subtotal,
                                descuentoPromos: descuentoPromos,
                                descuentoGral: descuentoGral,
                                totalIva: totalIva,
                                recargoRate: _recargoRate,
                                recargoAmount: _recargoAmount,
                                totalFinal: totalFinal,
                                productosState: productosState,
                            );
                        }
                    } else {
                        // If PaymentMethodsCubit is not available, show table without recargo
                        return _buildTable(
                            subtotal: subtotal,
                            descuentoPromos: descuentoPromos,
                            descuentoGral: descuentoGral,
                            totalIva: totalIva,
                            recargoRate: 0.0,
                            recargoAmount: 0.0,
                            totalFinal: subtotal - descuentoGral + totalIva,
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