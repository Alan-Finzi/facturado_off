
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import '../bloc/cubit_payment_methods/payment_methods_cubit.dart';
import '../bloc/cubit_productos/productos_cubit.dart';
import '../pages/page_forma_cobro.dart';


class ResumenTabla extends StatefulWidget {
    // Añadimos un callback para guardar
    final VoidCallback? onGuardarPressed;

    const ResumenTabla({super.key, this.onGuardarPressed});

    @override
    _ResumenTablaState createState() => _ResumenTablaState();
}

class _ResumenTablaState extends State<ResumenTabla> {
    // Store recargo information to persist between builds
    double _recargoRate = 0.0;
    double _recargoAmount = 0.0;
    int _lastMethodId = -1;
    int _lastProviderId = -1;
    StreamSubscription? _stateSubscription;

    @override
    void initState() {
        super.initState();
        // Initialize with a post-frame callback to ensure proper context
        WidgetsBinding.instance.addPostFrameCallback((_) {
            final PaymentMethodsCubit? paymentMethodsCubit = _getPaymentMethodsCubit(context);
            if (paymentMethodsCubit != null) {
                // Verificación de identidad de instancia - diagnóstico
                print('💰 ResumenTabla: PaymentMethodsCubit instance ID: ${paymentMethodsCubit.hashCode}');

                // Suscribirse directamente al stream de estados del Cubit
                _stateSubscription = paymentMethodsCubit.stream.listen((state) {
                    if (state is PaymentMethodsLoaded) {
                        // Verificar si hay cambio real en el método de pago o en el subtotal
                        final methodChanged = state.selectedMethodId != _lastMethodId ||
                                            state.selectedProviderId != _lastProviderId;

                        // Verificar si hay cambio en el subtotal
                        final subtotalChanged = state.subtotalAmount > 0;

                        // Actualizar si cambió el método o si hay subtotal y es la primera carga
                        if (methodChanged || subtotalChanged) {
                            _lastMethodId = state.selectedMethodId ?? -1;
                            _lastProviderId = state.selectedProviderId ?? -1;
                            _updateRecargoFromPaymentMethod(true, state);
                        }
                    }
                });

                // Actualizamos al inicio con el estado actual
                if (paymentMethodsCubit.state is PaymentMethodsLoaded) {
                    _updateRecargoFromPaymentMethod(true, paymentMethodsCubit.state as PaymentMethodsLoaded);
                }
            }
        });
    }

    @override
    void dispose() {
        _stateSubscription?.cancel();
        super.dispose();
    }

    // This method will force update the recargo information from the payment method
    void _updateRecargoFromPaymentMethod(bool forceUpdate, PaymentMethodsLoaded loadedState) {
        try {
            // SIEMPRE intentar obtener la información del método seleccionado
            double recargoRate = 0.0;
            double finalRecargoAmount = 0.0;

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

                                // Solo calcular el recargo si hay un subtotal válido
                                if (loadedState.subtotalAmount > 0) {
                                    // Cálculo directo del monto de recargo
                                    finalRecargoAmount = (loadedState.subtotalAmount * recargoRate) / 100;

                                    print('💰 CÁLCULO DIRECTO DEL RECARGO:');
                                    print('   Subtotal: ${loadedState.subtotalAmount.toStringAsFixed(2)}');
                                    print('   Tasa de recargo: ${recargoRate.toStringAsFixed(1)}%');
                                    print('   Monto de recargo: ${finalRecargoAmount.toStringAsFixed(2)}');
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
            }

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

                if (_recargoAmount > 0) {
                    print('✅ ResumenTabla: Recargo actualizado a ${_recargoAmount.toStringAsFixed(2)} (${_recargoRate.toStringAsFixed(1)}%)');
                } else if (_recargoRate > 0) {
                    print('⚠️ ResumenTabla: Recargo en 0 a pesar de tener tasa ${_recargoRate.toStringAsFixed(1)}%');
                } else {
                    print('ℹ️ ResumenTabla: Sin recargo (0%)');
                }
            }
        } catch (e) {
            print('🔴 Error general en _updateRecargoFromPaymentMethod: $e');
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
                                        _updateRecargoFromPaymentMethod(true, paymentState as PaymentMethodsLoaded);
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
                        decoration: _recargoAmount > 0 ? BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                        ) : null,
                        children: [
                            Padding(
                                padding: _recargoAmount > 0 ? EdgeInsets.all(4.0) : EdgeInsets.zero,
                                child: Row(
                                    children: [
                                        if (_recargoAmount > 0)
                                            Icon(Icons.payment, size: 12, color: Colors.red[700]),
                                        SizedBox(width: _recargoAmount > 0 ? 4.0 : 0),
                                        RichText(
                                            text: TextSpan(
                                                children: [
                                                    TextSpan(
                                                        text: '+ Recargo ',
                                                        style: TextStyle(
                                                            fontSize: _recargoAmount > 0 ? 11 : 10,
                                                            fontWeight: _recargoAmount > 0 ? FontWeight.bold : FontWeight.normal,
                                                            color: _recargoAmount > 0 ? Colors.red[700] : Colors.grey
                                                        ),
                                                    ),
                                                    TextSpan(
                                                        // Usar siempre los valores del estado interno
                                                        text: '(${_recargoRate.toStringAsFixed(1)}%)',
                                                        style: TextStyle(
                                                            fontSize: _recargoAmount > 0 ? 11 : 10,
                                                            fontWeight: _recargoAmount > 0 ? FontWeight.bold : FontWeight.normal,
                                                            color: _recargoAmount > 0 ? Colors.red[900] : Colors.grey,
                                                            backgroundColor: _recargoAmount > 0 ? Colors.yellow[100] : null,
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
                                padding: _recargoAmount > 0 ? EdgeInsets.all(4.0) : EdgeInsets.zero,
                                child: Text(
                                    // Usar siempre los valores del estado interno
                                    '+ \$${_recargoAmount.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontWeight: _recargoAmount > 0 ? FontWeight.bold : FontWeight.normal,
                                        color: _recargoAmount > 0 ? Colors.red[700] : Colors.grey,
                                        fontSize: _recargoAmount > 0 ? 12 : 10
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
                    // Agregar el botón Guardar
                    TableRow(
                        children: [
                            SizedBox(height: 20), // Espacio para separar
                            SizedBox(height: 20),
                        ],
                    ),
                    TableRow(
                        children: [
                            Container(), // Celda vacía a la izquierda
                            Container(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                    onPressed: widget.onGuardarPressed ?? () {
                                        // Si no hay callback, mostramos un mensaje
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Función de guardado no disponible'))
                                        );
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        minimumSize: Size(150, 50),
                                    ),
                                    child: const Text(
                                        'GUARDAR',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                        ),
                                    ),
                                ),
                            ),
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