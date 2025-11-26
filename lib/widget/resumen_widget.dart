
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
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
    Timer? _updateTimer;

    @override
    void initState() {
        super.initState();
        // Initialize with a post-frame callback to ensure proper context
        WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateRecargoFromPaymentMethod(true);

            // Set up a periodic timer to check for updates
            _updateTimer = Timer.periodic(Duration(milliseconds: 300), (_) {
                if (mounted) {
                    _updateRecargoFromPaymentMethod(false);
                }
            });
        });
    }

    @override
    void dispose() {
        _updateTimer?.cancel();
        super.dispose();
    }

    // This method will force update the recargo information from the payment method
    void _updateRecargoFromPaymentMethod(bool forceUpdate) {
        final PaymentMethodsCubit? paymentMethodsCubit = _getPaymentMethodsCubit(context);
        if (paymentMethodsCubit != null) {
            try {
                if (paymentMethodsCubit.state is PaymentMethodsLoaded) {
                    final loadedState = paymentMethodsCubit.state as PaymentMethodsLoaded;

                    // SIEMPRE intentar obtener la información del método seleccionado
                    double recargoRate = 0.0;
                    if (loadedState.selectedProviderId != null && loadedState.selectedMethodId != null) {
                        try {
                            // Intentar encontrar el proveedor seleccionado
                            final providerIndex = loadedState.providers.indexWhere(
                                (p) => p.id == loadedState.selectedProviderId
                            );

                            if (providerIndex >= 0) {
                                final selectedProvider = loadedState.providers[providerIndex];

                                // Intentar encontrar el método seleccionado
                                if (selectedProvider.metodosPago != null && selectedProvider.metodosPago!.isNotEmpty) {
                                    final methodIndex = selectedProvider.metodosPago!.indexWhere(
                                        (m) => m.id == loadedState.selectedMethodId
                                    );

                                    if (methodIndex >= 0) {
                                        final selectedMethod = selectedProvider.metodosPago![methodIndex];
                                        recargoRate = selectedMethod.recargo;

                                        // Cálculo directo del monto de recargo
                                        final directRecargoAmount = (loadedState.subtotalAmount * recargoRate) / 100;

                                        // Obtener el recargo del cubit para comparar
                                        final calculatedRecargoAmount = paymentMethodsCubit.getRecargoAmount();

                                        // Usar el recargo más alto entre ambos cálculos para asegurar que se muestre
                                        final finalRecargoAmount = max(directRecargoAmount, calculatedRecargoAmount);

                                        print('RECARGO DIRECTO: $directRecargoAmount | RECARGO CUBIT: $calculatedRecargoAmount | FINAL: $finalRecargoAmount');

                                        // Solo actualizar si hay cambios o se fuerza la actualización
                                        if (forceUpdate ||
                                            (_recargoRate != recargoRate) ||
                                            ((finalRecargoAmount - _recargoAmount).abs() > 0.001)) {

                                            if (mounted) {
                                                setState(() {
                                                    _recargoAmount = finalRecargoAmount;
                                                    _recargoRate = recargoRate;
                                                });
                                            }

                                            print('🔄 ResumenTabla: Recargo actualizado a ${_recargoAmount.toStringAsFixed(2)} (${_recargoRate.toStringAsFixed(1)}%)');
                                        }
                                    } else {
                                        print('⚠️ Método de pago no encontrado: ${loadedState.selectedMethodId}');
                                    }
                                } else {
                                    print('⚠️ Proveedor no tiene métodos: ${loadedState.selectedProviderId}');
                                }
                            } else {
                                print('⚠️ Proveedor no encontrado: ${loadedState.selectedProviderId}');
                            }
                        } catch (e) {
                            print('🔴 Error al buscar método de pago: $e');
                            print('StackTrace: ${StackTrace.current}');
                        }
                    } else {
                        if (mounted && _recargoAmount > 0) {
                            // Resetear el recargo si no hay método seleccionado
                            setState(() {
                                _recargoAmount = 0.0;
                                _recargoRate = 0.0;
                            });
                            print('🔄 ResumenTabla: Recargo reseteado a 0 (sin método seleccionado)');
                        }
                    }
                }
            } catch (e) {
                print('🔴 Error general en _updateRecargoFromPaymentMethod: $e');
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
                                        // Forzar actualización inmediata cuando cambia el estado
                                        _updateRecargoFromPaymentMethod(true);
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
                        decoration: (_recargoAmount > 0 || recargoAmount > 0) ? BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                        ) : null,
                        children: [
                            Padding(
                                padding: (_recargoAmount > 0 || recargoAmount > 0) ? EdgeInsets.all(4.0) : EdgeInsets.zero,
                                child: Row(
                                    children: [
                                        if (_recargoAmount > 0 || recargoAmount > 0)
                                            Icon(Icons.payment, size: 12, color: Colors.red[700]),
                                        SizedBox(width: (_recargoAmount > 0 || recargoAmount > 0) ? 4.0 : 0),
                                        RichText(
                                            text: TextSpan(
                                                children: [
                                                    TextSpan(
                                                        text: '+ Recargo ',
                                                        style: TextStyle(
                                                            fontSize: (_recargoAmount > 0 || recargoAmount > 0) ? 11 : 10,
                                                            fontWeight: (_recargoAmount > 0 || recargoAmount > 0) ? FontWeight.bold : FontWeight.normal,
                                                            color: (_recargoAmount > 0 || recargoAmount > 0) ? Colors.red[700] : Colors.grey
                                                        ),
                                                    ),
                                                    TextSpan(
                                                        // Usar el valor más actualizado: primero _recargoRate (state) luego recargoRate (parámetro)
                                                        text: '(${_recargoRate > 0 ? _recargoRate.toStringAsFixed(1) : recargoRate.toStringAsFixed(1)}%)',
                                                        style: TextStyle(
                                                            fontSize: (_recargoAmount > 0 || recargoAmount > 0) ? 11 : 10,
                                                            fontWeight: (_recargoAmount > 0 || recargoAmount > 0) ? FontWeight.bold : FontWeight.normal,
                                                            color: (_recargoAmount > 0 || recargoAmount > 0) ? Colors.red[900] : Colors.grey,
                                                            backgroundColor: (_recargoAmount > 0 || recargoAmount > 0) ? Colors.yellow[100] : null,
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
                                padding: (_recargoAmount > 0 || recargoAmount > 0) ? EdgeInsets.all(4.0) : EdgeInsets.zero,
                                child: Text(
                                    // Usar el valor más actualizado: primero _recargoAmount (state) luego recargoAmount (parámetro)
                                    '+ \$${_recargoAmount > 0 ? _recargoAmount.toStringAsFixed(2) : recargoAmount.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontWeight: (_recargoAmount > 0 || recargoAmount > 0) ? FontWeight.bold : FontWeight.normal,
                                        color: (_recargoAmount > 0 || recargoAmount > 0) ? Colors.red[700] : Colors.grey,
                                        fontSize: (_recargoAmount > 0 || recargoAmount > 0) ? 12 : 10
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