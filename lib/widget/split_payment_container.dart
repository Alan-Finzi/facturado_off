import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_payment_methods/payment_methods_cubit.dart';
import '../widget/split_payment_item_widget.dart';

/// Widget contenedor para el modo de pago dividido
///
/// Muestra la lista de items de pago y proporciona un botón para agregar nuevos items
class SplitPaymentContainer extends StatefulWidget {
  const SplitPaymentContainer({Key? key}) : super(key: key);

  @override
  State<SplitPaymentContainer> createState() => _SplitPaymentContainerState();
}

class _SplitPaymentContainerState extends State<SplitPaymentContainer> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Verificar si hay items de pago, si no, agregar uno inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<PaymentMethodsCubit>().state;
      if (state is PaymentMethodsLoaded &&
          state.isPartialPayment &&
          state.splitPayments.isEmpty) {
        context.read<PaymentMethodsCubit>().addSplitPaymentItem();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymentMethodsCubit, PaymentMethodsState>(
      listenWhen: (previous, current) {
        // Solo escuchar cambios cuando cambia de modo de pago o cuando cambian los items
        if (previous is PaymentMethodsLoaded && current is PaymentMethodsLoaded) {
          return previous.isPartialPayment != current.isPartialPayment ||
                 previous.splitPayments != current.splitPayments;
        }
        return false;
      },
      listener: (context, state) {
        if (state is PaymentMethodsLoaded && state.isPartialPayment) {
          // Si estamos en modo dividido y no hay items, agregar uno
          if (state.splitPayments.isEmpty) {
            context.read<PaymentMethodsCubit>().addSplitPaymentItem();
          }

          // Validar los pagos
          setState(() {
            _errorMessage = context.read<PaymentMethodsCubit>().validateSplitPayments();
          });
        }
      },
      builder: (context, state) {
        if (state is! PaymentMethodsLoaded || !state.isPartialPayment) {
          return const SizedBox(); // No mostrar nada si no es modo dividido
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado de la tabla
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Banco',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  const Expanded(
                    child: Text(
                      'Método',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  const SizedBox(
                    width: 100,
                    child: Text(
                      'Monto',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  const SizedBox(
                    width: 80,
                    child: Text(
                      'Recargo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  const SizedBox(
                    width: 100,
                    child: Text(
                      'Total a cobrar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  const SizedBox(
                    width: 48,
                    child: Text(
                      'Acción',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8.0),

            // Lista de items de pago
            ...state.splitPayments.items.map((item) =>
              SplitPaymentItemWidget(
                key: Key('split_item_${item.id}'),
                itemId: item.id,
                onDelete: (itemId) {
                  context.read<PaymentMethodsCubit>().removeSplitPaymentItem(itemId);
                },
              )
            ).toList(),

            const SizedBox(height: 8.0),

            // Botón para agregar nuevo método de pago
            ElevatedButton.icon(
              onPressed: () {
                context.read<PaymentMethodsCubit>().addSplitPaymentItem();
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar método'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),

            // Mensaje de error si existe
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(top: 8.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[800]),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16.0),

            // Resumen de los montos
            _buildPaymentsSummary(state),
          ],
        );
      },
    );
  }

  /// Construye el resumen de los pagos realizados
  Widget _buildPaymentsSummary(PaymentMethodsLoaded state) {
    // Calcular totales
    final double subtotalAmount = state.subtotalAmount;

    // Totales desde los items de pago
    final double totalInputAmount = state.splitPayments.items.fold(
      0.0, (sum, item) => sum + item.amount
    );

    final double totalRecargoAmount = state.splitPayments.items.fold(
      0.0, (sum, item) => sum + item.recargoAmount
    );

    final double totalAmount = subtotalAmount + totalRecargoAmount;
    final double remainingAmount = totalAmount - totalInputAmount;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total venta (con recargos):'),
              Text(
                '\$${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total a cobrar:'),
              Text(
                '\$${totalInputAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monto restante:',
                style: TextStyle(
                  color: remainingAmount > 0.01 ? Colors.red : Colors.grey[700],
                  fontWeight: remainingAmount > 0.01 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                '\$${remainingAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: remainingAmount > 0.01 ? Colors.red : Colors.grey[700],
                  fontWeight: remainingAmount > 0.01 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}