import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:facturador_offline/bloc/cubit_payment_methods/payment_methods_cubit.dart';
import 'package:facturador_offline/models/payment_provider.dart';
import 'package:facturador_offline/models/payment_method.dart';
import 'package:facturador_offline/models/split_payment_item.dart';

/// Widget para seleccionar métodos de pago en la versión móvil
/// Admite pago total y pago dividido (con múltiples métodos)
class PaymentMethodsWidget extends StatefulWidget {
  final double totalVenta;
  final Function(bool isPartialPayment, double recargo)? onPaymentTypeChanged;

  const PaymentMethodsWidget({
    Key? key,
    required this.totalVenta,
    this.onPaymentTypeChanged,
  }) : super(key: key);

  @override
  State<PaymentMethodsWidget> createState() => _PaymentMethodsWidgetState();
}

class _PaymentMethodsWidgetState extends State<PaymentMethodsWidget> {
  // Control para el monto ingresado
  final TextEditingController _inputAmountController = TextEditingController();

  // Estado local
  bool _isPartialPayment = false; // true: pago dividido, false: pago total
  double _recargo = 0.0;

  @override
  void initState() {
    super.initState();

    // Inicializar el input en 0 (se completa con "Pagar Monto Exacto")
    _inputAmountController.text = '0';

    // Actualizar el subtotal en el cubit e input en 0
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<PaymentMethodsCubit>();
      cubit.updateSubtotalAmount(widget.totalVenta);
      cubit.updateInputAmount(0);
    });
  }

  @override
  void didUpdateWidget(PaymentMethodsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si el total cambió, actualizar solo el subtotal en el cubit
    if (oldWidget.totalVenta != widget.totalVenta) {
      context.read<PaymentMethodsCubit>().updateSubtotalAmount(widget.totalVenta);
    }
  }

  @override
  void dispose() {
    _inputAmountController.dispose();
    super.dispose();
  }

  // Actualiza el monto ingresado
  void _updateInputAmount(double amount) {
    _inputAmountController.text = amount.toStringAsFixed(2);
    context.read<PaymentMethodsCubit>().updateInputAmount(amount);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentMethodsCubit, PaymentMethodsState>(
      builder: (context, state) {
        if (state is PaymentMethodsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is PaymentMethodsError) {
          return Center(child: Text('Error: ${state.message}'));
        } else if (state is PaymentMethodsEmpty) {
          return const Center(child: Text('No hay métodos de pago disponibles'));
        } else if (state is PaymentMethodsLoaded) {
          return _buildContent(context, state);
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  // Construye el contenido principal del widget
  Widget _buildContent(BuildContext context, PaymentMethodsLoaded state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector de tipo de pago
          _buildPaymentTypeSelector(),
          const SizedBox(height: 16),

          // Contenido según el tipo de pago
          _isPartialPayment
            ? _buildSplitPaymentContent(state)
            : _buildTotalPaymentContent(state),
        ],
      ),
    );
  }

  // Selector entre pago total y pago dividido
  Widget _buildPaymentTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Método de Cobro:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Botón Pago Total
            Expanded(
              child: ElevatedButton(
                onPressed: () => _setPaymentType(false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: !_isPartialPayment ? Colors.blue : Colors.grey.shade300,
                  foregroundColor: !_isPartialPayment ? Colors.white : Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Pago Total'),
              ),
            ),
            const SizedBox(width: 8),
            // Botón Pago Dividido
            Expanded(
              child: ElevatedButton(
                onPressed: () => _setPaymentType(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isPartialPayment ? Colors.blue : Colors.grey.shade300,
                  foregroundColor: _isPartialPayment ? Colors.white : Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Pago Dividido / CC'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Contenido para pago total
  Widget _buildTotalPaymentContent(PaymentMethodsLoaded state) {
    // Calcular recargo
    final recargoAmount = state.totalAmount - state.subtotalAmount;
    final recargoPercentage = state.selectedMethodId != null
        ? _findSelectedMethod(state)?.recargo ?? 0.0
        : 0.0;

    // Calcular vuelto
    final changeAmount = state.inputAmount - state.totalAmount;
    final hasChange = changeAmount > 0;
    final isInputValid = state.inputAmount >= state.totalAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selector de proveedor de pago
        _buildProviderSelector(state),
        const SizedBox(height: 12),

        // Selector de método de pago
        _buildMethodSelector(state),
        const SizedBox(height: 16),

        // Campo de entrada de monto
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingresa el monto:'),
            const SizedBox(height: 4),
            TextField(
              controller: _inputAmountController,
              decoration: InputDecoration(
                prefixText: ' ',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                errorText: !isInputValid ? 'El monto debe ser igual o mayor al total' : null,
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0;
                context.read<PaymentMethodsCubit>().updateInputAmount(amount);
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _updateInputAmount(state.totalAmount);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 40),
              ),
              child: const Text('Pagar Monto Exacto'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Mostrar resumen
        _buildPaymentSummary(
          subtotal: state.subtotalAmount,
          recargo: recargoAmount,
          recargoPercentage: recargoPercentage,
          total: state.totalAmount
        ),

        // Mostrar vuelto si aplica
        if (hasChange) ...[
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Vuelto a entregar:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text('\$${changeAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // Contenido para pago dividido
  Widget _buildSplitPaymentContent(PaymentMethodsLoaded state) {
    // Obtener los items de pago dividido
    final splitItems = state.splitPayments.items;

    // Calcular totales
    final totalPaid = state.splitPayments.getTotalWithoutRecargo();
    final totalWithRecargos = state.splitPayments.totalAmount;
    final remainingAmount = state.subtotalAmount - totalPaid;
    final totalRecargos = state.splitPayments.totalRecargoAmount;

    // Verificar si hay saldo pendiente
    final hasPendingBalance = remainingAmount > 0.01;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lista de items de pago
        if (splitItems.isNotEmpty) ...[
          const Text('Métodos de pago:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),

          // Tabla de pagos
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                // Encabezado de tabla
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: Colors.grey.shade100,
                  child: Row(
                    children: const [
                      Expanded(flex: 2, child: Text('Método', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Monto', style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: 40), // Espacio para botón eliminar
                    ],
                  ),
                ),

                // Items de pago
                ...splitItems.map((item) => _buildSplitPaymentItem(item, state)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Botón para agregar método de pago
        ElevatedButton.icon(
          onPressed: () {
            context.read<PaymentMethodsCubit>().addSplitPaymentItem();
          },
          icon: const Icon(Icons.add),
          label: const Text('Agregar método de pago'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            minimumSize: const Size(double.infinity, 40),
          ),
        ),
        const SizedBox(height: 16),

        // Resumen de pago dividido
        _buildSplitPaymentSummary(
          subtotal: state.subtotalAmount,
          totalPaid: totalPaid,
          totalWithRecargos: totalWithRecargos,
          recargos: totalRecargos,
          remainingAmount: remainingAmount,
          hasPendingBalance: hasPendingBalance,
        ),
      ],
    );
  }

  // Construye un item de pago dividido
  Widget _buildSplitPaymentItem(SplitPaymentItem item, PaymentMethodsLoaded state) {
    // Buscar proveedor y método seleccionado
    final provider = state.providers.firstWhere(
      (p) => p.id == item.providerId,
      orElse: () => state.providers.first,
    );

    final method = provider.metodosPago?.firstWhere(
      (m) => m.id == item.methodId,
      orElse: () => provider.metodosPago!.first,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // Método de pago (proveedor + método)
          Expanded(
            flex: 2,
            child: Text('${provider.nombre} - ${method?.nombre ?? ""}'),
          ),

          // Monto con recargo
          Expanded(
            flex: 1,
            child: Text('\$${item.totalAmount.toStringAsFixed(2)}'),
          ),

          // Botón eliminar
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () {
              context.read<PaymentMethodsCubit>().removeSplitPaymentItem(item.id);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // Selector de proveedor de pago
  Widget _buildProviderSelector(PaymentMethodsLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipo de cobro:'),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: ButtonTheme(
              alignedDropdown: true,
              child: DropdownButton<int>(
                value: state.selectedProviderId,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: state.providers.map((provider) {
                  return DropdownMenuItem<int>(
                    value: provider.id,
                    child: Text(provider.nombre),
                  );
                }).toList(),
                onChanged: (providerId) {
                  if (providerId != null) {
                    if (_isPartialPayment) {
                      // En pago dividido, mostrar diálogo para editar el item
                      _showSplitPaymentDialog(context);
                    } else {
                      // En pago total, cambiar directamente
                      context.read<PaymentMethodsCubit>().selectPaymentProvider(providerId);
                    }
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Selector de método de pago
  Widget _buildMethodSelector(PaymentMethodsLoaded state) {
    // Obtener los métodos del proveedor seleccionado
    final selectedProvider = state.providers.firstWhere(
      (p) => p.id == state.selectedProviderId,
      orElse: () => state.providers.first,
    );

    final methods = selectedProvider.metodosPago ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Forma de cobro:'),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: ButtonTheme(
              alignedDropdown: true,
              child: DropdownButton<int>(
                value: state.selectedMethodId,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: methods.map((method) {
                  return DropdownMenuItem<int>(
                    value: method.id,
                    child: Text('${method.nombre} ${method.recargo > 0 ? "(+${method.recargo}%)" : ""}'),
                  );
                }).toList(),
                onChanged: (methodId) {
                  if (methodId != null) {
                    if (_isPartialPayment) {
                      // En pago dividido, mostrar diálogo para editar el item
                      _showSplitPaymentDialog(context);
                    } else {
                      // En pago total, cambiar directamente
                      context.read<PaymentMethodsCubit>().selectPaymentMethod(methodId);

                      // Actualizar recargo local
                      setState(() {
                        _recargo = _findMethodById(state, methodId)?.recargo ?? 0.0;
                      });

                      // Actualizar input al nuevo total con recargo
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          final updatedState = context.read<PaymentMethodsCubit>().state;
                          if (updatedState is PaymentMethodsLoaded) {
                            _updateInputAmount(updatedState.totalAmount);
                          }
                        }
                      });

                      // Notificar cambio de recargo
                      if (widget.onPaymentTypeChanged != null) {
                        widget.onPaymentTypeChanged!(_isPartialPayment, _recargo);
                      }
                    }
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Resumen para pago total
  Widget _buildPaymentSummary({
    required double subtotal,
    required double recargo,
    required double recargoPercentage,
    required double total,
  }) {
    return Column(
      children: [
        const Divider(),
        // Subtotal
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Subtotal:', style: TextStyle(fontSize: 14)),
            Text('\$${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
          ],
        ),
        // Recargo (si hay)
        if (recargo > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recargo (${recargoPercentage.toStringAsFixed(1)}%):', style: const TextStyle(fontSize: 14)),
              Text('\$${recargo.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
        const SizedBox(height: 8),
        // Total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('\$${total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  // Resumen para pago dividido
  Widget _buildSplitPaymentSummary({
    required double subtotal,
    required double totalPaid,
    required double totalWithRecargos,
    required double recargos,
    required double remainingAmount,
    required bool hasPendingBalance,
  }) {
    return Column(
      children: [
        const Divider(),
        // Total de venta
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total venta:', style: TextStyle(fontSize: 14)),
            Text('\$${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
          ],
        ),
        // Total pagado
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total pagado:', style: TextStyle(fontSize: 14)),
            Text('\$${totalPaid.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
          ],
        ),
        // Recargos
        if (recargos > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recargos:', style: TextStyle(fontSize: 14)),
              Text('\$${recargos.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
        // Total con recargos
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total con recargos:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text('\$${totalWithRecargos.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Saldo pendiente
        if (hasPendingBalance) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Saldo pendiente:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              Text('\$${remainingAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Mensaje de advertencia
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: const [
                Icon(Icons.warning, color: Colors.red, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El saldo pendiente se guardará en la cuenta del cliente. Asegúrese de haber seleccionado un cliente.',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Mostrar diálogo para editar pago dividido
  void _showSplitPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _SplitPaymentDialog(
        onConfirm: (providerId, methodId, amount) {
          final state = context.read<PaymentMethodsCubit>().state;

          if (state is PaymentMethodsLoaded && state.splitPayments.items.isNotEmpty) {
            final itemId = state.splitPayments.items.last.id;

            // Actualizar el item
            context.read<PaymentMethodsCubit>()
              ..updateSplitItemProvider(itemId, providerId)
              ..updateSplitItemMethod(itemId, methodId)
              ..updateSplitItemAmount(itemId, amount);
          }
        },
        providers: context.read<PaymentMethodsCubit>().state is PaymentMethodsLoaded
          ? (context.read<PaymentMethodsCubit>().state as PaymentMethodsLoaded).providers
          : [],
        maxAmount: widget.totalVenta,
      ),
    );
  }

  // Cambiar tipo de pago (total/dividido)
  void _setPaymentType(bool isPartial) {
    if (_isPartialPayment == isPartial) return;

    setState(() {
      _isPartialPayment = isPartial;
    });

    // Notificar cambio de tipo de pago
    if (widget.onPaymentTypeChanged != null) {
      widget.onPaymentTypeChanged!(_isPartialPayment, _recargo);
    }

    // Actualizar cubit
    final cubit = context.read<PaymentMethodsCubit>();

    if (isPartial) {
      // Cambiar a pago dividido
      cubit.setPaymentType(true);

      // Agregar primer item si no hay
      final state = cubit.state;
      if (state is PaymentMethodsLoaded && state.splitPayments.items.isEmpty) {
        cubit.addSplitPaymentItem();
      }
    } else {
      // Cambiar a pago total
      cubit.setPaymentType(false);

      // Restaurar monto de entrada al total
      _updateInputAmount(widget.totalVenta);
    }
  }

  // Encontrar el método de pago seleccionado
  PaymentMethod? _findSelectedMethod(PaymentMethodsLoaded state) {
    if (state.selectedProviderId == null || state.selectedMethodId == null) {
      return null;
    }

    // Buscar el proveedor
    final selectedProvider = state.providers.firstWhere(
      (p) => p.id == state.selectedProviderId,
      orElse: () => state.providers.first,
    );

    // Buscar el método
    if (selectedProvider.metodosPago == null || selectedProvider.metodosPago!.isEmpty) {
      return null;
    }

    return selectedProvider.metodosPago!.firstWhere(
      (m) => m.id == state.selectedMethodId,
      orElse: () => selectedProvider.metodosPago!.first,
    );
  }

  // Buscar método por ID
  PaymentMethod? _findMethodById(PaymentMethodsLoaded state, int methodId) {
    for (final provider in state.providers) {
      if (provider.metodosPago != null) {
        for (final method in provider.metodosPago!) {
          if (method.id == methodId) {
            return method;
          }
        }
      }
    }
    return null;
  }
}

/// Diálogo para editar un item de pago dividido
class _SplitPaymentDialog extends StatefulWidget {
  final Function(int providerId, int methodId, double amount) onConfirm;
  final List<PaymentProvider> providers;
  final double maxAmount;

  const _SplitPaymentDialog({
    Key? key,
    required this.onConfirm,
    required this.providers,
    required this.maxAmount,
  }) : super(key: key);

  @override
  State<_SplitPaymentDialog> createState() => _SplitPaymentDialogState();
}

class _SplitPaymentDialogState extends State<_SplitPaymentDialog> {
  late int _selectedProviderId;
  late int _selectedMethodId;
  final TextEditingController _amountController = TextEditingController();
  double _recargo = 0.0;
  double _amount = 0.0;
  double _total = 0.0;

  @override
  void initState() {
    super.initState();

    // Inicializar con el primer proveedor y método
    _selectedProviderId = widget.providers.first.id;
    _selectedMethodId = widget.providers.first.metodosPago?.first.id ?? 0;

    // Inicializar monto con el máximo
    _amount = widget.maxAmount;
    _amountController.text = _amount.toStringAsFixed(2);

    // Calcular recargo inicial
    _updateRecargo();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // Actualizar recargo cuando cambia el método
  void _updateRecargo() {
    // Buscar el método seleccionado
    PaymentMethod? selectedMethod;
    for (final provider in widget.providers) {
      if (provider.id == _selectedProviderId && provider.metodosPago != null) {
        for (final method in provider.metodosPago!) {
          if (method.id == _selectedMethodId) {
            selectedMethod = method;
            break;
          }
        }
        if (selectedMethod != null) break;
      }
    }

    // Actualizar recargo
    final recargoPercentage = selectedMethod?.recargo ?? 0.0;
    _recargo = (_amount * recargoPercentage / 100);
    _total = _amount + _recargo;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar método de pago'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de proveedor
            const Text('Tipo de cobro:'),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: ButtonTheme(
                  alignedDropdown: true,
                  child: DropdownButton<int>(
                    value: _selectedProviderId,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: widget.providers.map((provider) {
                      return DropdownMenuItem<int>(
                        value: provider.id,
                        child: Text(provider.nombre),
                      );
                    }).toList(),
                    onChanged: (providerId) {
                      if (providerId != null) {
                        setState(() {
                          _selectedProviderId = providerId;

                          // Actualizar método seleccionado al primero del proveedor
                          final provider = widget.providers.firstWhere(
                            (p) => p.id == providerId,
                            orElse: () => widget.providers.first,
                          );

                          _selectedMethodId = provider.metodosPago?.first.id ?? 0;

                          _updateRecargo();
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Selector de método
            const Text('Forma de cobro:'),
            const SizedBox(height: 4),
            Builder(
              builder: (context) {
                // Buscar el proveedor seleccionado
                final selectedProvider = widget.providers.firstWhere(
                  (p) => p.id == _selectedProviderId,
                  orElse: () => widget.providers.first,
                );

                // Obtener los métodos
                final methods = selectedProvider.metodosPago ?? [];

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: ButtonTheme(
                      alignedDropdown: true,
                      child: DropdownButton<int>(
                        value: _selectedMethodId,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: methods.map((method) {
                          return DropdownMenuItem<int>(
                            value: method.id,
                            child: Text('${method.nombre} ${method.recargo > 0 ? "(+${method.recargo}%)" : ""}'),
                          );
                        }).toList(),
                        onChanged: (methodId) {
                          if (methodId != null) {
                            setState(() {
                              _selectedMethodId = methodId;
                              _updateRecargo();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Campo de monto
            const Text('Monto:'),
            const SizedBox(height: 4),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                prefixText: ' ',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0;
                setState(() {
                  _amount = amount;
                  _updateRecargo();
                });
              },
            ),
            const SizedBox(height: 16),

            // Resumen
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  // Monto base
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Monto base:'),
                      Text('\$${_amount.toStringAsFixed(2)}'),
                    ],
                  ),
                  // Recargo
                  if (_recargo > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recargo:'),
                        Text('\$${_recargo.toStringAsFixed(2)}'),
                      ],
                    ),
                  ],
                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total a cobrar:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('\$${_total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfirm(_selectedProviderId, _selectedMethodId, _amount);
            Navigator.of(context).pop();
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}