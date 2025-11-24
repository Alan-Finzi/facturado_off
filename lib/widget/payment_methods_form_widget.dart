import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_payment_methods/payment_methods_cubit.dart';
import '../bloc/cubit_productos/productos_cubit.dart';

/// Widget que implementa la UI para seleccionar forma de pago
/// y calcular recargos y vueltos
class PaymentMethodsFormWidget extends StatefulWidget {
  const PaymentMethodsFormWidget({Key? key}) : super(key: key);

  @override
  _PaymentMethodsFormWidgetState createState() => _PaymentMethodsFormWidgetState();
}

class _PaymentMethodsFormWidgetState extends State<PaymentMethodsFormWidget> {
  final TextEditingController _inputAmountController = TextEditingController();
  final FocusNode _inputAmountFocusNode = FocusNode();
  String? _inputError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<ProductosCubit>().state;
      // Obtener el total de la venta desde el cubit de productos
      double subtotal = 0.0;
      for (var producto in state.productosSeleccionados) {
        final precioLista = producto.precioLista ?? 0;
        final cantidad = producto.cantidad ?? 1;
        subtotal += precioLista * cantidad;
      }

      // Actualizar el subtotal en el PaymentMethodsCubit
      context.read<PaymentMethodsCubit>().updateSubtotalAmount(subtotal);

      // Cargar los proveedores y métodos de pago
      context.read<PaymentMethodsCubit>().loadPaymentProviders();
    });

    _inputAmountFocusNode.addListener(() {
      if (!_inputAmountFocusNode.hasFocus) {
        _validateAmount();
      }
    });
  }

  @override
  void dispose() {
    _inputAmountController.dispose();
    _inputAmountFocusNode.dispose();
    super.dispose();
  }

  void _validateAmount() {
    final paymentMethodsCubit = context.read<PaymentMethodsCubit>();
    final errorMsg = paymentMethodsCubit.validateInputAmount();
    setState(() {
      _inputError = errorMsg;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentMethodsCubit, PaymentMethodsState>(
      builder: (context, state) {
        if (state is PaymentMethodsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PaymentMethodsEmpty) {
          return const Center(
            child: Text('No hay métodos de pago disponibles. Sincronice su aplicación.'),
          );
        }

        if (state is PaymentMethodsError) {
          return Center(
            child: Text('Error: ${state.message}'),
          );
        }

        if (state is PaymentMethodsLoaded) {
          // Actualizar el controlador si el valor cambia en el estado
          if (_inputAmountController.text.isEmpty ||
              double.tryParse(_inputAmountController.text) != state.inputAmount) {
            _inputAmountController.text = state.inputAmount > 0
                ? state.inputAmount.toStringAsFixed(2)
                : '';
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tipo de pago (total o parcial)
              Text(
                'Forma de cobro',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<PaymentMethodsCubit>().setPaymentType(false);
                      },
                      child: Text('Pago total'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !state.isPartialPayment ? Colors.grey : null,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<PaymentMethodsCubit>().setPaymentType(true);
                      },
                      child: Text('Pago parcial / pago dividido'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.isPartialPayment ? Colors.grey : null,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.0),

              // Contenido basado en tipo de pago
              if (state.isPartialPayment)
                _buildPartialPaymentContent(context, state)
              else
                _buildTotalPaymentContent(context, state),
            ],
          );
        }

        // Estado inicial o no controlado
        return const Center(child: Text('Cargando opciones de pago...'));
      },
    );
  }

  // Construye la UI para pago parcial
  Widget _buildPartialPaymentContent(BuildContext context, PaymentMethodsLoaded state) {
    final paymentMethodsCubit = context.read<PaymentMethodsCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // UI de dos columnas
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Columna izquierda: Selección de método de pago
            Expanded(
              child: _buildPaymentMethodSelectors(context, state),
            ),
            SizedBox(width: 16.0),
            // Columna derecha: Resumen de montos
            Expanded(
              child: _buildTotalsColumn(context, state),
            ),
          ],
        ),

        // Botón para agregar otro método de pago
        TextButton(
          onPressed: () {
            // Aquí iría la lógica para agregar otro método de pago
          },
          child: Text(
            '+ Agregar Método de Pago',
            style: TextStyle(color: Colors.orange),
          ),
        ),
        SizedBox(height: 16.0),

        // Monto total y A cobrar total
        Row(
          children: [
            // Monto Total
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Monto Total',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                controller: TextEditingController(
                    text: state.totalAmount.toStringAsFixed(2)),
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 16.0),
            // A Cobrar Total
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'A cobrar total',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(
                    text: state.inputAmount.toStringAsFixed(2)),
                onChanged: (value) {
                  final amount = double.tryParse(value) ?? 0.0;
                  paymentMethodsCubit.updateInputAmount(amount);
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 8.0),

        // Deuda (diferencia entre total y monto ingresado)
        Text(
          'Deuda: \$ ${(state.totalAmount - state.inputAmount).toStringAsFixed(2)}',
          style: TextStyle(
            color: state.totalAmount > state.inputAmount ? Colors.red : Colors.black,
          ),
        ),
      ],
    );
  }

  // Construye la UI para pago total
  Widget _buildTotalPaymentContent(BuildContext context, PaymentMethodsLoaded state) {
    final paymentMethodsCubit = context.read<PaymentMethodsCubit>();
    final recargoAmount = paymentMethodsCubit.getChangeAmount();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // UI de dos columnas
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Columna izquierda: Selección de método de pago
            Expanded(
              child: _buildPaymentMethodSelectors(context, state),
            ),
            SizedBox(width: 16.0),
            // Columna derecha: Monto y resumen
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Monto a pagar
                  TextField(
                    controller: _inputAmountController,
                    focusNode: _inputAmountFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Ingresa el monto con el que va a pagar tu cliente',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                      errorText: _inputError,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    onChanged: (value) {
                      final amount = double.tryParse(value) ?? 0.0;
                      paymentMethodsCubit.updateInputAmount(amount);
                      _validateAmount();
                    },
                  ),
                  SizedBox(height: 10.0),

                  // Botón "Paga el total"
                  ElevatedButton(
                    onPressed: () {
                      paymentMethodsCubit.setPayTotalAmount();
                      // Actualizar el controlador con el nuevo valor
                      _inputAmountController.text = state.totalAmount.toStringAsFixed(2);
                      _validateAmount();
                    },
                    child: Text('Paga el total'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                  SizedBox(height: 16.0),

                  // Monto con recargo
                  Text(
                    'Total (incluye recargo): \$${state.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  // Mostrar detalles del recargo si existe
                  if (paymentMethodsCubit.getRecargoAmount() > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Recargo: \$${paymentMethodsCubit.getRecargoAmount().toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),

                  SizedBox(height: 16.0),

                  // Vuelto a entregar (si corresponde)
                  if (state.inputAmount >= state.totalAmount)
                    Text(
                      'Vuelto a entregar: \$${(state.inputAmount - state.totalAmount).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    )
                  else if (state.inputAmount > 0)
                    Text(
                      'Falta: \$${(state.totalAmount - state.inputAmount).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Construye la columna de totales para el pago parcial
  Widget _buildTotalsColumn(BuildContext context, PaymentMethodsLoaded state) {
    final paymentMethodsCubit = context.read<PaymentMethodsCubit>();
    final recargoAmount = paymentMethodsCubit.getRecargoAmount();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mostrar subtotal y recargo
        Text(
          'Subtotal: \$${state.subtotalAmount.toStringAsFixed(2)}',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        if (recargoAmount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Recargo (${_getSelectedMethodRate(state)}%): \$${recargoAmount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 14),
            ),
          ),
        Divider(),
        Text(
          'Total: \$${state.totalAmount.toStringAsFixed(2)}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  // Obtiene la tasa de recargo del método seleccionado
  String _getSelectedMethodRate(PaymentMethodsLoaded state) {
    if (state.selectedProviderId != null && state.selectedMethodId != null) {
      for (final provider in state.providers) {
        if (provider.id == state.selectedProviderId && provider.metodosPago != null) {
          for (final method in provider.metodosPago!) {
            if (method.id == state.selectedMethodId) {
              return method.recargo.toString();
            }
          }
        }
      }
    }
    return '0';
  }

  // Construye los selectores de método de pago (tipo de cobro y forma de cobro)
  Widget _buildPaymentMethodSelectors(BuildContext context, PaymentMethodsLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tipo de cobro (dropdown de providers)
        Text('Tipo de cobro:', style: TextStyle(fontWeight: FontWeight.w500)),
        DropdownButton<int>(
          value: state.selectedProviderId,
          isExpanded: true,
          hint: Text('Seleccione tipo de cobro'),
          onChanged: (int? providerId) {
            if (providerId != null) {
              context.read<PaymentMethodsCubit>().selectPaymentProvider(providerId);
            }
          },
          items: state.providers.map((provider) {
            return DropdownMenuItem<int>(
              value: provider.id,
              child: Text(provider.nombre),
            );
          }).toList(),
        ),
        SizedBox(height: 16.0),

        // Forma de cobro (dropdown de métodos del provider seleccionado)
        Text('Forma de cobro:', style: TextStyle(fontWeight: FontWeight.w500)),
        _buildPaymentMethodsDropdown(context, state),
      ],
    );
  }

  // Construye el dropdown de métodos de pago basado en el proveedor seleccionado
  Widget _buildPaymentMethodsDropdown(BuildContext context, PaymentMethodsLoaded state) {
    // Encontrar el proveedor seleccionado
    final selectedProvider = state.selectedProviderId != null
        ? state.providers.firstWhere(
            (p) => p.id == state.selectedProviderId,
            orElse: () => null as PaymentProvider,
          )
        : null;

    // Si no hay proveedor seleccionado o no tiene métodos, mostrar dropdown vacío
    if (selectedProvider == null ||
        selectedProvider.metodosPago == null ||
        selectedProvider.metodosPago!.isEmpty) {
      return DropdownButton<int>(
        isExpanded: true,
        hint: Text('No hay métodos disponibles'),
        onChanged: null,
        items: [],
      );
    }

    // Construir dropdown con los métodos del proveedor seleccionado
    return DropdownButton<int>(
      value: state.selectedMethodId,
      isExpanded: true,
      hint: Text('Seleccione forma de cobro'),
      onChanged: (int? methodId) {
        if (methodId != null) {
          context.read<PaymentMethodsCubit>().selectPaymentMethod(methodId);
        }
      },
      items: selectedProvider.metodosPago!.map((method) {
        String label = method.nombre;
        if (method.recargo > 0) {
          label += ' (+${method.recargo}% recargo)';
        }

        return DropdownMenuItem<int>(
          value: method.id,
          child: Text(label),
        );
      }).toList(),
    );
  }
}