import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_payment_methods/payment_methods_cubit.dart';
import '../bloc/cubit_productos/productos_cubit.dart';
import '../models/payment_provider.dart';

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
              // Título de método de cobro
              Text(
                'Método de cobro',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 16.0),

              // Botones de tipo de pago (total o parcial)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<PaymentMethodsCubit>().setPaymentType(false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !state.isPartialPayment ? Colors.grey[700] : null,
                      ),
                      child: Text('Pago total'),
                    ),
                  ),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<PaymentMethodsCubit>().setPaymentType(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.isPartialPayment ? Colors.grey[700] : null,
                        side: state.isPartialPayment ? null : BorderSide(color: Colors.grey),
                      ),
                      child: Text('Pago dividido o en Cuenta Corriente'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.0),

              // Dos columnas: Métodos de pago y monto a pagar
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna izquierda: Selectores de método de pago
                  Expanded(
                    child: Column(
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
                    ),
                  ),
                  SizedBox(width: 16.0),

                  // Columna derecha: Monto a pagar
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
                            context.read<PaymentMethodsCubit>().updateInputAmount(amount);
                            _validateAmount();
                          },
                        ),
                        SizedBox(height: 10.0),

                        // Botón "Paga el total"
                        Row(
                          children: [
                            Expanded(
                              child: Container(), // Espacio vacío a la izquierda
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                context.read<PaymentMethodsCubit>().setPayTotalAmount();
                                _inputAmountController.text = state.totalAmount.toStringAsFixed(2);
                                _validateAmount();
                              },
                              icon: Icon(Icons.money),
                              label: Text('Pagar el total'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                backgroundColor: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.0),

                        // Vuelto a entregar (si corresponde)
                        if (state.inputAmount >= state.totalAmount)
                          Container(
                            padding: EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              border: Border.all(color: Colors.green),
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.payments, color: Colors.green),
                                SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    'Vuelto a entregar: \$${(state.inputAmount - state.totalAmount).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (state.inputAmount > 0)
                          Container(
                            padding: EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              border: Border.all(color: Colors.red),
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber, color: Colors.red),
                                SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    'Falta: \$${(state.totalAmount - state.inputAmount).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[700],
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.0),

              // Total con recargo
              Row(
                children: [
                  Text(
                    'Total (incluye recargo): ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${state.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),

              // Mostrar detalles del recargo si existe
              if (context.read<PaymentMethodsCubit>().getRecargoAmount() > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Recargo: \$${context.read<PaymentMethodsCubit>().getRecargoAmount().toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          );
        }

        // Estado inicial o no controlado
        return const Center(child: Text('Cargando opciones de pago...'));
      },
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

  // Construye el dropdown de métodos de pago basado en el proveedor seleccionado
  Widget _buildPaymentMethodsDropdown(BuildContext context, PaymentMethodsLoaded state) {
    // Encontrar el proveedor seleccionado
    PaymentProvider? selectedProvider;

    if (state.selectedProviderId != null) {
      try {
        selectedProvider = state.providers.firstWhere(
          (p) => p.id == state.selectedProviderId,
        );
      } catch (e) {
        // Si no se encuentra, dejamos selectedProvider como null
        print('Proveedor con ID ${state.selectedProviderId} no encontrado');
      }
    }

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