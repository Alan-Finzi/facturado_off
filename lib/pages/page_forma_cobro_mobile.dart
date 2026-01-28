import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import '../bloc/cubit_login/login_cubit.dart';
import '../bloc/cubit_payment_methods/payment_methods_cubit.dart';
import '../bloc/cubit_productos/productos_cubit.dart';
import '../models/split_payment_collection.dart';
import '../widget/split_payment_container.dart';
import '../util/platform_service.dart';

/// Página de forma de cobro optimizada para dispositivos móviles
class FormaCobroPageMobile extends StatefulWidget {
  const FormaCobroPageMobile({Key? key}) : super(key: key);

  @override
  State<FormaCobroPageMobile> createState() => _FormaCobroPageMobileState();
}

class _FormaCobroPageMobileState extends State<FormaCobroPageMobile> {
  String? _selectedCaja = 'Caja #10';
  bool _isResumenExpanded = true;
  String _tipoDePago = 'Efectivo';
  double? _descuento = 0.0;

  // Tipo de pago seleccionado (simple o dividido)
  String _tipoPago = 'simple';

  // Método para alternar entre pago simple y dividido
  void _togglePagoMode() {
    setState(() {
      _tipoPago = _tipoPago == 'simple' ? 'dividido' : 'simple';
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch PaymentMethods state
    final paymentMethodsCubit = context.watch<PaymentMethodsCubit>();
    final paymentMethodsState = paymentMethodsCubit.state;

    // Get current products and total
    final productosCubit = context.watch<ProductosCubit>();
    final subtotal = productosCubit.calcularSubtotal();
    final iva = productosCubit.calcularIva();
    final descuentoGeneral = productosCubit.state.descuentoGeneral;
    final montoDescuento = subtotal * (descuentoGeneral / 100);
    final totalFinal = subtotal - montoDescuento + iva;

    // Get selected client
    final clienteCubit = context.watch<ClientesMostradorCubit>();
    final clienteSeleccionado = clienteCubit.state.clienteSeleccionado;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forma de Cobro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Guardar venta',
            onPressed: () => _confirmarVenta(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Cliente y caja seleccionados
          _buildHeaderPanel(clienteSeleccionado?.nombre ?? 'Consumidor Final'),

          // Contenido principal
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector de tipo de pago
                  _buildTipoPagoSelector(),

                  const SizedBox(height: 16),

                  // Contenedor de forma de pago (simple o dividido)
                  _tipoPago == 'simple'
                      ? _buildPagoSimple(paymentMethodsCubit, paymentMethodsState, totalFinal)
                      : const SplitPaymentContainer(),

                  // Resumen de venta expandible
                  _buildResumenVenta(subtotal, iva, descuentoGeneral, montoDescuento, totalFinal, paymentMethodsState),
                ],
              ),
            ),
          ),

          // Botones de acción
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  Widget _buildHeaderPanel(String nombreCliente) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // Cliente
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cliente:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  nombreCliente,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Caja seleccionada
          DropdownButton<String>(
            value: _selectedCaja,
            items: const [
              DropdownMenuItem(value: 'Caja #10', child: Text('Caja #10')),
              DropdownMenuItem(value: 'Caja #11', child: Text('Caja #11')),
              DropdownMenuItem(value: 'Caja #12', child: Text('Caja #12')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCaja = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTipoPagoSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipo de Pago',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Pago Simple'),
                    selected: _tipoPago == 'simple',
                    onSelected: (_) {
                      if (_tipoPago != 'simple') {
                        setState(() {
                          _tipoPago = 'simple';
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Pago Dividido'),
                    selected: _tipoPago == 'dividido',
                    onSelected: (_) {
                      if (_tipoPago != 'dividido') {
                        setState(() {
                          _tipoPago = 'dividido';
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagoSimple(PaymentMethodsCubit paymentMethodsCubit, paymentMethodsState, double total) {
    final tipoDePagoOptions = ['Efectivo', 'Tarjeta de Crédito', 'Tarjeta de Débito', 'Transferencia', 'Cuenta Corriente'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Método de Pago',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _tipoDePago,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              items: tipoDePagoOptions.map((tipo) {
                return DropdownMenuItem<String>(
                  value: tipo,
                  child: Text(tipo),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _tipoDePago = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_tipoDePago == 'Cuenta Corriente')
              const Text(
                'El monto será añadido a la cuenta corriente del cliente.',
                style: TextStyle(
                  color: Colors.blue,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenVenta(double subtotal, double iva, double descuentoGeneral,
      double montoDescuento, double totalFinal, paymentMethodsState) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Header expandible
          InkWell(
            onTap: () {
              setState(() {
                _isResumenExpanded = !_isResumenExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text(
                    'Resumen de Venta',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isResumenExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                ],
              ),
            ),
          ),

          // Contenido expandible
          if (_isResumenExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(),

                  // Subtotal
                  _buildResumenRow('Subtotal:', '\$${subtotal.toStringAsFixed(2)}'),

                  // Descuento general
                  if (descuentoGeneral > 0)
                    _buildResumenRow('Descuento (${descuentoGeneral.round()}%):', '- \$${montoDescuento.toStringAsFixed(2)}'),

                  // IVA
                  _buildResumenRow('IVA:', '+ \$${iva.toStringAsFixed(2)}'),

                  // Recargo si hay
                  if (paymentMethodsState is PaymentMethodsLoaded && paymentMethodsState.isPartialPayment)
                    _buildResumenRow(
                      'Recargo:',
                      '+ \$${paymentMethodsState.splitPayments.totalRecargoAmount.toStringAsFixed(2)}',
                      valueStyle: const TextStyle(color: Colors.red),
                    ),

                  // Monto para cuenta corriente
                  if (paymentMethodsState is PaymentMethodsLoaded &&
                      paymentMethodsState.isPartialPayment &&
                      paymentMethodsState.splitPayments.remainingAmount > 0.01)
                    _buildResumenRow(
                      'Monto para cuenta corriente:',
                      '\$${paymentMethodsState.splitPayments.remainingAmount.toStringAsFixed(2)}',
                      rowColor: Colors.blue.shade50,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                      valueStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                      icon: Icons.account_balance_wallet,
                    ),

                  const Divider(),

                  // TOTAL
                  _buildResumenRow(
                    'TOTAL:',
                    '\$${totalFinal.toStringAsFixed(2)}',
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    valueStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResumenRow(
    String label,
    String value, {
    TextStyle? labelStyle,
    TextStyle? valueStyle,
    Color? rowColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: rowColor != null ? BorderRadius.circular(4) : null,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: labelStyle?.color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: labelStyle ?? const TextStyle(fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: valueStyle ?? const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _confirmarVenta(context),
              icon: const Icon(Icons.save),
              label: const Text('Guardar Venta'),
            ),
          ),
        ],
      ),
    );
  }

  // Método para mostrar el diálogo de confirmación de venta
  void _confirmarVenta(BuildContext context) {
    final productosState = context.read<ProductosCubit>().state;
    final productos = productosState.productosSeleccionados;
    final clienteCubit = context.read<ClientesMostradorCubit>();
    final cliente = clienteCubit.state.clienteSeleccionado;
    final paymentMethodsCubit = context.read<PaymentMethodsCubit>();

    // Calcular totales
    final subtotal = productosCubit.calcularSubtotal();
    final descuentoGeneral = productosState.descuentoGeneral;
    final montoDescuento = subtotal * (descuentoGeneral / 100);
    final iva = productosCubit.calcularIva();
    final total = subtotal - montoDescuento + iva;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Confirmar venta'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Por favor confirme los detalles de la venta:'),
              const SizedBox(height: 16),

              // Cliente
              const Text('Cliente:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(cliente?.nombre ?? 'Consumidor final'),
              const SizedBox(height: 8),

              // Productos
              const Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...productos.map((producto) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(producto.producto?.name ?? 'Producto sin nombre'),
                        ),
                        Text('\$${producto.precioLista?.toStringAsFixed(2) ?? '0.00'}'),
                      ],
                    ),
                  )),
              const Divider(),

              // Información del monto restante (para pagos divididos)
              Builder(
                builder: (context) {
                  // Verificar si es pago dividido
                  if (paymentMethodsCubit.state is PaymentMethodsLoaded) {
                    final state = paymentMethodsCubit.state as PaymentMethodsLoaded;

                    if (state.isPartialPayment) {
                      // Calcular total pagado
                      final totalPagado = state.splitPayments.items.fold(
                        0.0,
                        (sum, item) => sum + item.amount
                      );

                      // Calcular total con recargos
                      final totalConRecargos = state.subtotalAmount +
                        state.splitPayments.items.fold(0.0, (sum, item) => sum + item.recargoAmount);

                      // Mostrar información de montos pagados/pendientes
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total a pagar:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('\$${totalConRecargos.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Monto pagado:', style: TextStyle(color: Colors.green.shade800)),
                              Text('\$${totalPagado.toStringAsFixed(2)}',
                                  style: TextStyle(color: Colors.green.shade800)),
                            ],
                          ),
                          if (totalPagado < totalConRecargos - 0.01) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Monto restante:',
                                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                Text('\$${(totalConRecargos - totalPagado).toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.account_balance_wallet, size: 16, color: Colors.blue[700]),
                                    const SizedBox(width: 4),
                                    Text('Monto para cuenta corriente:',
                                        style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Text('\$${(totalConRecargos - totalPagado).toStringAsFixed(2)}',
                                    style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                          const Divider(),
                        ],
                      );
                    }
                  }
                  return const SizedBox.shrink(); // No mostrar nada si no es pago dividido
                },
              ),

              // Mostrar totales
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:', style: TextStyle(fontSize: 14)),
                  Text('\$${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
                ],
              ),
              if (descuentoGeneral > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Descuento (${descuentoGeneral.round()}%):', style: const TextStyle(fontSize: 14)),
                    Text('- \$${montoDescuento.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
                  ],
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('IVA:', style: TextStyle(fontSize: 14)),
                  Text('\$${iva.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // Guardar venta y salir
              Navigator.of(context).pop(); // Cerrar diálogo
              Navigator.of(context).pop(); // Volver a pantalla anterior
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}