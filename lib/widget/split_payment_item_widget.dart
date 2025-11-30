import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_payment_methods/payment_methods_cubit.dart';
import '../models/split_payment_item.dart';
import '../models/payment_provider.dart';

/// Widget que representa un item de pago individual en el modo pago dividido
class SplitPaymentItemWidget extends StatelessWidget {
  /// ID único del item de pago
  final String itemId;

  /// Callback para eliminar este item
  final Function(String) onDelete;

  /// Constructor
  const SplitPaymentItemWidget({
    Key? key,
    required this.itemId,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentMethodsCubit, PaymentMethodsState>(
      builder: (context, state) {
        if (state is! PaymentMethodsLoaded) {
          return const SizedBox();
        }

        final currentState = state as PaymentMethodsLoaded;

        // Buscar el item actual en la colección
        final item = currentState.splitPayments.items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => throw Exception('Item no encontrado'),
        );

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Proveedor (Banco)
                Expanded(
                  child: _buildProviderDropdown(context, currentState, item),
                ),
                const SizedBox(width: 8.0),

                // Método
                Expanded(
                  child: _buildMethodDropdown(context, currentState, item),
                ),
                const SizedBox(width: 8.0),

                // Monto
                _buildAmountInput(context, item),
                const SizedBox(width: 8.0),

                // Recargo
                _buildRecargoDisplay(item),
                const SizedBox(width: 8.0),

                // Total a cobrar
                _buildTotalDisplay(item),
                const SizedBox(width: 8.0),

                // Botón eliminar
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDelete(itemId),
                  tooltip: 'Eliminar método de pago',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Construye el dropdown para seleccionar el proveedor
  Widget _buildProviderDropdown(
    BuildContext context,
    PaymentMethodsLoaded state,
    SplitPaymentItem item
  ) {
    return DropdownButton<int>(
      value: item.providerId,
      isExpanded: true,
      hint: const Text('Tipo de cobro'),
      onChanged: (int? providerId) {
        if (providerId != null) {
          context.read<PaymentMethodsCubit>().updateSplitItemProvider(
            itemId,
            providerId
          );
        }
      },
      items: state.providers.map((provider) {
        return DropdownMenuItem<int>(
          value: provider.id,
          child: Text(
            provider.nombre,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }

  /// Construye el dropdown para seleccionar el método de pago
  Widget _buildMethodDropdown(
    BuildContext context,
    PaymentMethodsLoaded state,
    SplitPaymentItem item
  ) {
    // Encontrar el proveedor seleccionado
    PaymentProvider? selectedProvider;
    if (item.providerId != null) {
      try {
        selectedProvider = state.providers.firstWhere(
          (p) => p.id == item.providerId,
        );
      } catch (e) {
        // No hacer nada si no se encuentra el proveedor
      }
    }

    // Si no hay proveedor seleccionado, mostrar dropdown vacío
    if (selectedProvider == null ||
        selectedProvider.metodosPago == null ||
        selectedProvider.metodosPago!.isEmpty) {
      return DropdownButton<int>(
        isExpanded: true,
        hint: const Text('Seleccione tipo de cobro primero'),
        onChanged: null,
        items: const [],
      );
    }

    // Mostrar dropdown con los métodos del proveedor
    return DropdownButton<int>(
      value: item.methodId,
      isExpanded: true,
      hint: const Text('Forma de cobro'),
      onChanged: (int? methodId) {
        if (methodId != null) {
          context.read<PaymentMethodsCubit>().updateSplitItemMethod(
            itemId,
            methodId
          );
        }
      },
      items: selectedProvider.metodosPago!.map((method) {
        String label = method.nombre;
        if (method.recargo > 0) {
          label += ' (+${method.recargo}% recargo)';
        }

        return DropdownMenuItem<int>(
          value: method.id,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }

  /// Construye el campo de entrada para el monto
  Widget _buildAmountInput(BuildContext context, SplitPaymentItem item) {
    final controller = TextEditingController(
      text: item.amount > 0 ? item.amount.toStringAsFixed(2) : '',
    );

    return SizedBox(
      width: 100,
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Monto',
          prefixText: '\$ ',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
        onChanged: (value) {
          final amount = double.tryParse(value) ?? 0.0;
          context.read<PaymentMethodsCubit>().updateSplitItemAmount(
            itemId,
            amount
          );
        },
      ),
    );
  }

  /// Construye la visualización del recargo
  Widget _buildRecargoDisplay(SplitPaymentItem item) {
    final bool hasRecargo = item.recargoPercentage > 0;

    return Container(
      width: 80,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: hasRecargo ? Colors.red[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '${item.recargoPercentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: hasRecargo ? FontWeight.bold : FontWeight.normal,
              color: hasRecargo ? Colors.red : Colors.grey[700],
            ),
          ),
          Text(
            '\$${item.recargoAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: hasRecargo ? FontWeight.bold : FontWeight.normal,
              color: hasRecargo ? Colors.red : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la visualización del total
  Widget _buildTotalDisplay(SplitPaymentItem item) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '\$${item.totalAmount.toStringAsFixed(2)}',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue[800],
        ),
      ),
    );
  }
}