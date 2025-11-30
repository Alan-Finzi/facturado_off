import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_payment_methods/payment_methods_cubit.dart';
import '../bloc/cubit_productos/productos_cubit.dart';
import '../models/payment_provider.dart';
import 'split_payment_container.dart';

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
      // Verificación de identidad de instancia - diagnóstico
      final paymentMethodsCubit = context.read<PaymentMethodsCubit>();
      print('💳 PaymentMethodsFormWidget: PaymentMethodsCubit instance ID: ${paymentMethodsCubit.hashCode}');

      final productosState = context.read<ProductosCubit>().state;
      // Obtener el total de la venta desde el cubit de productos
      double subtotal = 0.0;
      double totalIva = 0.0;

      // Calcular subtotal y IVA
      for (var producto in productosState.productosSeleccionados) {
        final precioLista = producto.precioLista ?? 0;
        final cantidad = producto.cantidad ?? 1;
        final precioFinal = producto.precioFinal ?? 0;

        subtotal += precioLista * cantidad;
        totalIva += (precioFinal - (precioLista * cantidad));
      }

      // Calcular descuento general
      final descuentoGral = (productosState.descuentoGeneral / 100) * subtotal;

      // Calcular el monto subtotal (ya con descuento e IVA) para usarse en el recargo
      final subtotalParaRecargo = subtotal - descuentoGral + totalIva;

      // Actualizar el subtotal en el PaymentMethodsCubit
      context.read<PaymentMethodsCubit>().updateSubtotalAmount(subtotalParaRecargo);

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

              // Contenido condicional basado en el modo de pago
              state.isPartialPayment
                ? SplitPaymentContainer() // Mostrar el contenedor de pagos divididos
                : Row(
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
                          // Monto a pagar y botón en layout horizontal
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Campo de entrada para el monto
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _inputAmountController,
                                  focusNode: _inputAmountFocusNode,
                                  decoration: InputDecoration(
                                    labelText: 'Ingresa el monto',
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
                              ),

                              // Espacio entre el campo de texto y el botón
                              SizedBox(width: 10.0),

                              // Botón "Paga el total" con el nuevo estilo
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: () {
                                  // Obtener la instancia actualizada del PaymentMethodsCubit
                                  final paymentMethodsCubit = context.read<PaymentMethodsCubit>();

                                  try {
                                    print('=== PAGAR TOTAL - Iniciando cálculos ===');

                                    // Forzar una actualización del subtotal para recalcular el recargo
                                    final productosState = context.read<ProductosCubit>().state;

                                    // Calcular subtotal y IVA desde ProductosCubit
                                    double subtotal = 0.0;
                                    double totalIva = 0.0;

                                    for (var producto in productosState.productosSeleccionados) {
                                      final precioLista = producto.precioLista ?? 0;
                                      final cantidad = producto.cantidad ?? 1;
                                      final precioFinal = producto.precioFinal ?? 0;

                                      subtotal += precioLista * cantidad;
                                      totalIva += (precioFinal - (precioLista * cantidad));
                                    }

                                    // Calcular descuento general
                                    final descuentoGral = (productosState.descuentoGeneral / 100) * subtotal;

                                    // Calcular el subtotal para recargo
                                    final subtotalParaRecargo = subtotal - descuentoGral + totalIva;

                                    print('Subtotal para recargo: \$${subtotalParaRecargo.toStringAsFixed(2)}');

                                    // Ejecutar actualizaciones en secuencia específica para asegurar consistencia

                                    // Paso 1: Establecer el subtotal correcto
                                    paymentMethodsCubit.updateSubtotalAmount(subtotalParaRecargo);

                                    // Obtener método actual e información
                                    String metodoPago = "ninguno";
                                    double recargoAmount = 0.0;
                                    double totalWithRecargo = subtotalParaRecargo;

                                    if (state.selectedMethodId != null && state.selectedProviderId != null) {
                                      print('Método de pago seleccionado. ID: ${state.selectedMethodId}, Proveedor: ${state.selectedProviderId}');
                                      metodoPago = "ID: ${state.selectedMethodId}";

                                      // Paso 2: Re-seleccionar el método y proveedor para garantizar cálculos correctos
                                      paymentMethodsCubit.selectPaymentProvider(state.selectedProviderId!);
                                      paymentMethodsCubit.selectPaymentMethod(state.selectedMethodId!);

                                      // Paso 3: Actualizar subtotal nuevamente para asegurar cálculo de recargo
                                      paymentMethodsCubit.updateSubtotalAmount(subtotalParaRecargo);

                                      // Obtener recargo calculado
                                      recargoAmount = paymentMethodsCubit.getRecargoAmount();
                                      print('Recargo calculado: \$${recargoAmount.toStringAsFixed(2)}');

                                      // Calcular total con recargo
                                      totalWithRecargo = subtotalParaRecargo + recargoAmount;
                                      print('Total con recargo: \$${totalWithRecargo.toStringAsFixed(2)}');
                                    } else {
                                      print('Sin método de pago seleccionado, usando total sin recargo');
                                    }

                                    // Actualizar inmediatamente la UI para mejor experiencia de usuario
                                    setState(() {
                                      _inputAmountController.text = totalWithRecargo.toStringAsFixed(2);
                                    });

                                    // Importante: Establecer el total en el estado
                                    paymentMethodsCubit.setPayTotalAmount();

                                    // Secuencia mejorada para garantizar que todos los componentes se actualicen correctamente
                                    Future.delayed(Duration(milliseconds: 50), () {
                                      try {
                                        // Verificar que el estado está correctamente sincronizado
                                        if (paymentMethodsCubit.state is PaymentMethodsLoaded) {
                                          final currentState = paymentMethodsCubit.state as PaymentMethodsLoaded;
                                          final stateAmount = currentState.totalAmount;
                                          final difference = (stateAmount - totalWithRecargo).abs();

                                          // Asegurar que el recargo se aplica correctamente
                                          if (state.selectedMethodId != null) {
                                            print('Forzando actualización de recargo para método: ${state.selectedMethodId}');

                                            // Secuencia de actualizaciones espaciadas para garantizar propagación
                                            paymentMethodsCubit.updateSubtotalAmount(subtotalParaRecargo);
                                            paymentMethodsCubit.selectPaymentProvider(state.selectedProviderId!);
                                            paymentMethodsCubit.selectPaymentMethod(state.selectedMethodId!);

                                            // Segunda verificación del recargo
                                            final updatedRecargoAmount = paymentMethodsCubit.getRecargoAmount();
                                            print('Recargo recalculado: \$${updatedRecargoAmount.toStringAsFixed(2)}');

                                            // Forzar otra actualización después de un breve retraso
                                            Future.delayed(Duration(milliseconds: 50), () {
                                              // Re-aplicar los valores para forzar la notificación de cambio
                                              paymentMethodsCubit.updateSubtotalAmount(subtotalParaRecargo);
                                              paymentMethodsCubit.selectPaymentMethod(state.selectedMethodId!);
                                              paymentMethodsCubit.setPayTotalAmount();

                                              // Actualizar UI si es necesario
                                              if (mounted) {
                                                setState(() {
                                                  _inputAmountController.text = paymentMethodsCubit.state is PaymentMethodsLoaded
                                                      ? (paymentMethodsCubit.state as PaymentMethodsLoaded).totalAmount.toStringAsFixed(2)
                                                      : totalWithRecargo.toStringAsFixed(2);
                                                  _validateAmount();
                                                });
                                              }

                                              print('Sincronización completada con múltiples actualizaciones');
                                            });
                                          } else {
                                            print('No hay método de pago seleccionado, no se aplica recargo');
                                          }
                                        }
                                      } catch (e) {
                                        print('Error en verificación posterior: $e');
                                      }
                                    });

                                    // Registrar información para depuración
                                    print('=== PAGAR TOTAL - Resumen ===');
                                    print('Subtotal: \$${subtotal.toStringAsFixed(2)}');
                                    print('IVA: \$${totalIva.toStringAsFixed(2)}');
                                    print('Descuento: \$${descuentoGral.toStringAsFixed(2)}');
                                    print('Método de pago: $metodoPago');
                                    print('Recargo: \$${recargoAmount.toStringAsFixed(2)}');
                                    print('Total final: \$${totalWithRecargo.toStringAsFixed(2)}');
                                    print('=== PAGAR TOTAL - Finalizado ===');

                                    // Validar el monto para mostrar mensajes de error si los hay
                                    _validateAmount();
                                  } catch (e) {
                                    print('Error en Pagar total: $e');
                                    print('StackTrace: ${StackTrace.current}');

                                    // En caso de error, usar el total disponible en el estado actual
                                    final currentTotal = state.totalAmount;
                                    print('Usando total del estado por error: $currentTotal');

                                    // Asegurar que se establece el monto total en el estado
                                    paymentMethodsCubit.setPayTotalAmount();

                                    // Actualizar la interfaz de usuario
                                    setState(() {
                                      _inputAmountController.text = currentTotal.toStringAsFixed(2);
                                      _validateAmount();
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  side: BorderSide(color: Colors.black),
                                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: Text(
                                  'Pagar total',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.0),

                        // Vuelto a entregar (si corresponde) - Solo se muestra en modo pago total
                        if (!state.isPartialPayment) {
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
                        }
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.0),

              // Espacio para mayor separación visual
              SizedBox(height: 8.0),
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
          // Obtener la instancia del cubit
          final paymentMethodsCubit = context.read<PaymentMethodsCubit>();
          final productosState = context.read<ProductosCubit>().state;

          print('=== CAMBIO DE MÉTODO DE PAGO - Iniciando cálculos ===');
          print('Método seleccionado ID: $methodId');

          try {
            // Calcular subtotal y IVA desde ProductosCubit para asegurar valores actualizados
            double subtotal = 0.0;
            double totalIva = 0.0;

            for (var producto in productosState.productosSeleccionados) {
              final precioLista = producto.precioLista ?? 0;
              final cantidad = producto.cantidad ?? 1;
              final precioFinal = producto.precioFinal ?? 0;

              subtotal += precioLista * cantidad;
              totalIva += (precioFinal - (precioLista * cantidad));
            }

            // Calcular descuento general
            final descuentoGral = (productosState.descuentoGeneral / 100) * subtotal;

            // Calcular el subtotal para recargo
            final subtotalParaRecargo = subtotal - descuentoGral + totalIva;
            print('Subtotal calculado para recargo: \$${subtotalParaRecargo.toStringAsFixed(2)}');

            // Secuencia optimizada para actualización de estado, garantizando que ResumenTabla
            // reciba los eventos correctamente

            // IMPORTANTE: Notificar a los listeners que vamos a hacer cambios importantes
            print('=== AVISO DE CAMBIO IMPORTANTE DE MÉTODO DE PAGO ===');
            print('Método seleccionado: $methodId con recargo pendiente de calcular');

            // 1. Primero actualiza el subtotal - esto es crítico para cálculos precisos
            paymentMethodsCubit.updateSubtotalAmount(subtotalParaRecargo);

            // 2. Luego seleccionar el proveedor si es necesario para mantener consistencia
            if (state.selectedProviderId != null) {
              paymentMethodsCubit.selectPaymentProvider(state.selectedProviderId!);
            }

            // Secuencia mejorada con retrasos cortos para garantizar la propagación correcta de eventos

            // 3. Seleccionar el método de pago para calcular el recargo con el subtotal correcto
            paymentMethodsCubit.selectPaymentMethod(methodId);

            // 4. Verificar el recargo calculado
            double recargoAmount = paymentMethodsCubit.getRecargoAmount();
            print('Recargo calculado: \$${recargoAmount.toStringAsFixed(2)} (${methodId})');
            double totalConRecargo = subtotalParaRecargo + recargoAmount;
            print('Total con recargo: \$${totalConRecargo.toStringAsFixed(2)}');

            // 5. Secuencia de actualización con retrasos para garantizar propagación correcta
            Future.delayed(Duration(milliseconds: 50), () {
              // Forzar una segunda actualización del subtotal
              paymentMethodsCubit.updateSubtotalAmount(subtotalParaRecargo);

              // Re-seleccionar el método para asegurar consistencia
              paymentMethodsCubit.selectPaymentMethod(methodId);

              // Disparar una tercera ronda de actualizaciones después de un breve retraso
              Future.delayed(Duration(milliseconds: 50), () {
                // Volver a establecer el subtotal y método
                paymentMethodsCubit.updateSubtotalAmount(subtotalParaRecargo);
                paymentMethodsCubit.selectPaymentMethod(methodId);

                // Verificar el recargo final
                final finalRecargoAmount = paymentMethodsCubit.getRecargoAmount();
                print('Recargo final (después de múltiples actualizaciones): \$${finalRecargoAmount.toStringAsFixed(2)}');
                print('=== CAMBIO DE MÉTODO DE PAGO - Finalizado ===');

                // Asegurarse de que la UI se actualice correctamente
                if (paymentMethodsCubit.state is PaymentMethodsLoaded) {
                  // Modificación sutil de estado para forzar actualizaciones en todos los widgets
                  final currentState = paymentMethodsCubit.state as PaymentMethodsLoaded;
                  if (currentState.subtotalAmount > 0) {
                    // Actualizar con el mismo valor para forzar notificación de cambio
                    paymentMethodsCubit.updateSubtotalAmount(currentState.subtotalAmount);
                  }
                }
              });
            });

          } catch (e) {
            print('Error al cambiar método de pago: $e');
            print('StackTrace: ${StackTrace.current}');
            // Fallback a la implementación original con más seguridad
            try {
              paymentMethodsCubit.selectPaymentMethod(methodId);
              if (paymentMethodsCubit.state is PaymentMethodsLoaded) {
                final currentState = paymentMethodsCubit.state as PaymentMethodsLoaded;
                if (currentState.subtotalAmount > 0) {
                  paymentMethodsCubit.updateSubtotalAmount(currentState.subtotalAmount);
                  print('Recuperación completada usando fallback');
                }
              }
            } catch (innerError) {
              print('Error en fallback: $innerError');
            }
          }
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