import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:facturador_offline/bloc/cubit_payment_methods/payment_methods_cubit.dart';
import 'package:facturador_offline/models/payment_provider.dart';
import 'package:facturador_offline/models/payment_method.dart';
import 'package:facturador_offline/models/split_payment_item.dart';

/// Widget para seleccionar métodos de pago en la versión móvil.
/// Admite pago total (un método) y pago dividido (múltiples métodos con recargos individuales).
class PaymentMethodsWidget extends StatefulWidget {
  final double totalVenta;
  final Function(bool isPartialPayment, double recargo)? onPaymentTypeChanged;
  final Function(double discountPct)? onAdditionalDiscountChanged;

  const PaymentMethodsWidget({
    Key? key,
    required this.totalVenta,
    this.onPaymentTypeChanged,
    this.onAdditionalDiscountChanged,
  }) : super(key: key);

  @override
  State<PaymentMethodsWidget> createState() => _PaymentMethodsWidgetState();
}

class _PaymentMethodsWidgetState extends State<PaymentMethodsWidget> {
  final TextEditingController _inputAmountController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: '0');

  bool _isPartialPayment = false;
  double _recargo = 0.0;
  double _additionalDiscountPct = 0.0;

  @override
  void initState() {
    super.initState();
    _inputAmountController.text = '0';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<PaymentMethodsCubit>();
      cubit.updateSubtotalAmount(widget.totalVenta);
      cubit.updateInputAmount(0);
    });
  }

  @override
  void didUpdateWidget(PaymentMethodsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalVenta != widget.totalVenta) {
      context.read<PaymentMethodsCubit>().updateSubtotalAmount(widget.totalVenta);
    }
  }

  @override
  void dispose() {
    _inputAmountController.dispose();
    _discountController.dispose();
    super.dispose();
  }

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
          _buildPaymentTypeSelector(),
          const SizedBox(height: 16),
          _isPartialPayment
              ? _buildSplitPaymentContent(state)
              : _buildTotalPaymentContent(state),
        ],
      ),
    );
  }

  // ── Selector Pago Total / Pago Dividido ──────────────────────────────────

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

  // ── Pago Total ───────────────────────────────────────────────────────────

  Widget _buildTotalPaymentContent(PaymentMethodsLoaded state) {
    final recargoAmount = state.totalAmount - state.subtotalAmount;
    final recargoPercentage = state.selectedMethodId != null
        ? _findSelectedMethod(state)?.recargo ?? 0.0
        : 0.0;
    final discountAmount = state.subtotalAmount * _additionalDiscountPct / 100;
    final totalConDescuento = state.totalAmount - discountAmount;
    final changeAmount = state.inputAmount - totalConDescuento;
    final hasChange = changeAmount > 0;
    final isInputValid = state.inputAmount >= totalConDescuento;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProviderSelector(state),
        const SizedBox(height: 12),
        _buildMethodSelector(state),
        const SizedBox(height: 16),

        // Descuento adicional
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Descuento adicional (%):'),
            const SizedBox(height: 4),
            TextField(
              controller: _discountController,
              decoration: const InputDecoration(
                suffixText: '%',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                setState(() {
                  _additionalDiscountPct = (double.tryParse(value) ?? 0.0).clamp(0.0, 100.0);
                });
                widget.onAdditionalDiscountChanged?.call(_additionalDiscountPct);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Monto ingresado
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingresa el monto:'),
            const SizedBox(height: 4),
            TextField(
              controller: _inputAmountController,
              decoration: InputDecoration(
                prefixText: '\$ ',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                errorText: !isInputValid ? 'El monto debe ser igual o mayor al total' : null,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0;
                context.read<PaymentMethodsCubit>().updateInputAmount(amount);
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _updateInputAmount(totalConDescuento),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 40),
              ),
              child: const Text('Pagar Monto Exacto'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildPaymentSummary(
          subtotal: state.subtotalAmount,
          descuentoAdicional: discountAmount,
          descuentoAdicionalPct: _additionalDiscountPct,
          recargo: recargoAmount,
          recargoPercentage: recargoPercentage,
          total: totalConDescuento,
        ),

        if (hasChange) ...[
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Vuelto a entregar:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('\$${changeAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
            ],
          ),
        ],
      ],
    );
  }

  // ── Pago Dividido ────────────────────────────────────────────────────────

  Widget _buildSplitPaymentContent(PaymentMethodsLoaded state) {
    final splitItems = state.splitPayments.items;
    final cubit = context.read<PaymentMethodsCubit>();

    final totalBase = splitItems.fold(0.0, (sum, item) => sum + item.amount);
    final totalRecargos = splitItems.fold(0.0, (sum, item) => sum + item.recargoAmount);
    final totalACobrar = totalBase + totalRecargos;
    final saldoPendiente = (state.subtotalAmount - totalBase).clamp(0.0, double.infinity);
    final hasPendingBalance = saldoPendiente > 0.01;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarjetas inline por método de pago
        ...splitItems.asMap().entries.map((e) => _SplitItemEditor(
              key: ValueKey(e.value.id),
              item: e.value,
              providers: state.providers,
              itemNumber: e.key + 1,
              cubit: cubit,
            )),

        // Botón agregar
        OutlinedButton.icon(
          onPressed: () => cubit.addSplitPaymentItem(),
          icon: const Icon(Icons.add),
          label: const Text('Agregar método de pago'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
            side: const BorderSide(color: Colors.blue),
            foregroundColor: Colors.blue,
          ),
        ),
        const SizedBox(height: 16),

        _buildSplitPaymentSummary(
          subtotal: state.subtotalAmount,
          totalBase: totalBase,
          totalRecargos: totalRecargos,
          totalACobrar: totalACobrar,
          saldoPendiente: saldoPendiente,
          hasPendingBalance: hasPendingBalance,
          items: splitItems,
        ),
      ],
    );
  }

  // ── Selectores de proveedor / método (pago total) ────────────────────────

  Widget _buildProviderSelector(PaymentMethodsLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipo de cobro:'),
        const SizedBox(height: 4),
        _buildDropdownContainer(
          child: DropdownButton<int>(
            value: state.selectedProviderId,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down),
            items: state.providers.map((p) => DropdownMenuItem<int>(
              value: p.id,
              child: Text(p.nombre),
            )).toList(),
            onChanged: (providerId) {
              if (providerId != null) {
                context.read<PaymentMethodsCubit>().selectPaymentProvider(providerId);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMethodSelector(PaymentMethodsLoaded state) {
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
        _buildDropdownContainer(
          child: DropdownButton<int>(
            value: state.selectedMethodId,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down),
            items: methods.map((m) => DropdownMenuItem<int>(
              value: m.id,
              child: Text('${m.nombre}${m.recargo > 0 ? " (+${m.recargo.toStringAsFixed(0)}%)" : ""}'),
            )).toList(),
            onChanged: (methodId) {
              if (methodId != null) {
                context.read<PaymentMethodsCubit>().selectPaymentMethod(methodId);
                setState(() {
                  _recargo = _findMethodById(state, methodId)?.recargo ?? 0.0;
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    final updatedState = context.read<PaymentMethodsCubit>().state;
                    if (updatedState is PaymentMethodsLoaded) {
                      final discount = updatedState.subtotalAmount * _additionalDiscountPct / 100;
                      _updateInputAmount(updatedState.totalAmount - discount);
                    }
                  }
                });
                widget.onPaymentTypeChanged?.call(_isPartialPayment, _recargo);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(alignedDropdown: true, child: child),
      ),
    );
  }

  // ── Resúmenes ────────────────────────────────────────────────────────────

  Widget _buildPaymentSummary({
    required double subtotal,
    required double descuentoAdicional,
    required double descuentoAdicionalPct,
    required double recargo,
    required double recargoPercentage,
    required double total,
  }) {
    return Column(
      children: [
        const Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Subtotal:', style: TextStyle(fontSize: 14)),
          Text('\$${subtotal.toStringAsFixed(2)}'),
        ]),
        if (recargo > 0)
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Recargo (${recargoPercentage.toStringAsFixed(1)}%):'),
            Text('+\$${recargo.toStringAsFixed(2)}'),
          ]),
        if (descuentoAdicional > 0)
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Descuento (${descuentoAdicionalPct.toStringAsFixed(1)}%):',
                style: const TextStyle(color: Colors.green)),
            Text('-\$${descuentoAdicional.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.green)),
          ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('\$${total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
      ],
    );
  }

  Widget _buildSplitPaymentSummary({
    required double subtotal,
    required double totalBase,
    required double totalRecargos,
    required double totalACobrar,
    required double saldoPendiente,
    required bool hasPendingBalance,
    required List<SplitPaymentItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total venta:', style: TextStyle(fontSize: 14)),
          Text('\$${subtotal.toStringAsFixed(2)}'),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Monto asignado:', style: TextStyle(fontSize: 14)),
          Text('\$${totalBase.toStringAsFixed(2)}'),
        ]),
        if (totalRecargos > 0) ...[
          ...items.where((i) => i.recargoAmount > 0).map((i) {
            final idx = items.indexOf(i) + 1;
            return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                '  Recargo ${i.recargoPercentage.toStringAsFixed(0)}% (pago #$idx):',
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              ),
              Text('+\$${i.recargoAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, color: Colors.orange)),
            ]);
          }),
        ],
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('TOTAL A COBRAR:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('\$${totalACobrar.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        if (hasPendingBalance) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Saldo pendiente \$${saldoPendiente.toStringAsFixed(2)} irá a cuenta corriente del cliente.',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _setPaymentType(bool isPartial) {
    if (_isPartialPayment == isPartial) return;
    setState(() {
      _isPartialPayment = isPartial;
    });
    widget.onPaymentTypeChanged?.call(_isPartialPayment, _recargo);

    final cubit = context.read<PaymentMethodsCubit>();
    if (isPartial) {
      cubit.setPaymentType(true);
      final state = cubit.state;
      if (state is PaymentMethodsLoaded && state.splitPayments.items.isEmpty) {
        cubit.addSplitPaymentItem();
      }
    } else {
      cubit.setPaymentType(false);
      _updateInputAmount(widget.totalVenta);
    }
  }

  PaymentMethod? _findSelectedMethod(PaymentMethodsLoaded state) {
    if (state.selectedProviderId == null || state.selectedMethodId == null) return null;
    final provider = state.providers.firstWhere(
      (p) => p.id == state.selectedProviderId,
      orElse: () => state.providers.first,
    );
    if (provider.metodosPago == null || provider.metodosPago!.isEmpty) return null;
    return provider.metodosPago!.firstWhere(
      (m) => m.id == state.selectedMethodId,
      orElse: () => provider.metodosPago!.first,
    );
  }

  PaymentMethod? _findMethodById(PaymentMethodsLoaded state, int methodId) {
    for (final provider in state.providers) {
      if (provider.metodosPago != null) {
        for (final method in provider.metodosPago!) {
          if (method.id == methodId) return method;
        }
      }
    }
    return null;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Tarjeta inline para editar un ítem de pago dividido
// ════════════════════════════════════════════════════════════════════════════

class _SplitItemEditor extends StatefulWidget {
  final SplitPaymentItem item;
  final List<PaymentProvider> providers;
  final int itemNumber;
  final PaymentMethodsCubit cubit;

  const _SplitItemEditor({
    Key? key,
    required this.item,
    required this.providers,
    required this.itemNumber,
    required this.cubit,
  }) : super(key: key);

  @override
  State<_SplitItemEditor> createState() => _SplitItemEditorState();
}

class _SplitItemEditorState extends State<_SplitItemEditor> {
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.item.amount > 0 ? widget.item.amount.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final providers = widget.providers;

    // Proveedor seleccionado (validar que exista)
    final selectedProvider = providers.firstWhere(
      (p) => p.id == item.providerId,
      orElse: () => providers.first,
    );
    final methods = selectedProvider.metodosPago ?? [];

    // Validar que el methodId sea del proveedor actual
    final validMethodId = methods.any((m) => m.id == item.methodId)
        ? item.methodId
        : (methods.isNotEmpty ? methods.first.id : null);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Pago #N + botón eliminar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pago #${widget.itemNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              InkWell(
                onTap: () => widget.cubit.removeSplitPaymentItem(item.id),
                child: const Icon(Icons.close, color: Colors.red, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tipo de cobro (provider)
          const Text('Tipo de cobro:',
              style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          _buildDropdown(
            value: item.providerId,
            items: providers
                .map((p) => DropdownMenuItem(value: p.id, child: Text(p.nombre)))
                .toList(),
            onChanged: (id) {
              if (id != null) widget.cubit.updateSplitItemProvider(item.id, id);
            },
          ),
          const SizedBox(height: 10),

          // Forma de cobro (method)
          const Text('Forma de cobro:',
              style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          _buildDropdown(
            value: validMethodId,
            items: methods
                .map((m) => DropdownMenuItem(
                      value: m.id,
                      child: Text(
                        '${m.nombre}${m.recargo > 0 ? " (+${m.recargo.toStringAsFixed(0)}%)" : ""}',
                      ),
                    ))
                .toList(),
            onChanged: (id) {
              if (id != null) widget.cubit.updateSplitItemMethod(item.id, id);
            },
          ),
          const SizedBox(height: 10),

          // Monto base
          const Text('Monto a asignar:',
              style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              prefixText: '\$ ',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final amount = double.tryParse(value) ?? 0.0;
              widget.cubit.updateSplitItemAmount(item.id, amount);
            },
          ),

          // Resultado del recargo + total a cobrar
          if (item.amount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (item.recargoAmount > 0)
                    Text(
                      'Recargo ${item.recargoPercentage.toStringAsFixed(0)}%: +\$${item.recargoAmount.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                    )
                  else
                    const Text('Sin recargo',
                        style: TextStyle(fontSize: 12, color: Colors.green)),
                  Text(
                    'A cobrar: \$${item.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required int? value,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<int>(
            value: value,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
