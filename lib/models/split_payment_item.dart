import 'package:flutter/foundation.dart';
import 'package:facturador_offline/models/payment_method.dart';

/// Modelo que representa un item de pago individual en un pago dividido
///
/// Cada item contiene la información de un método de pago específico,
/// el monto ingresado y el recargo calculado.
class SplitPaymentItem {
  /// ID único del item (generado localmente para identificación)
  final String id;

  /// ID del proveedor seleccionado
  final int? providerId;

  /// ID del método de pago seleccionado
  final int? methodId;

  /// Monto ingresado por el cliente para este método de pago
  final double amount;

  /// Porcentaje de recargo del método seleccionado
  final double recargoPercentage;

  /// Monto calculado de recargo
  final double recargoAmount;

  /// Total a cobrar (amount + recargoAmount)
  final double totalAmount;

  SplitPaymentItem({
    required this.id,
    this.providerId,
    this.methodId,
    this.amount = 0.0,
    this.recargoPercentage = 0.0,
    this.recargoAmount = 0.0,
    this.totalAmount = 0.0,
  });

  /// Crea una copia del item con algunos campos actualizados
  SplitPaymentItem copyWith({
    String? id,
    int? providerId,
    int? methodId,
    double? amount,
    double? recargoPercentage,
    double? recargoAmount,
    double? totalAmount,
  }) {
    return SplitPaymentItem(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      methodId: methodId ?? this.methodId,
      amount: amount ?? this.amount,
      recargoPercentage: recargoPercentage ?? this.recargoPercentage,
      recargoAmount: recargoAmount ?? this.recargoAmount,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  /// Calcula el recargo y total basado en el monto y porcentaje de recargo
  SplitPaymentItem calculateAmounts({
    double? newAmount,
    double? newRecargoPercentage,
  }) {
    final calculationAmount = newAmount ?? amount;
    final calculationRecargoPercentage = newRecargoPercentage ?? recargoPercentage;

    final calculatedRecargoAmount = (calculationAmount * calculationRecargoPercentage) / 100;
    final calculatedTotalAmount = calculationAmount + calculatedRecargoAmount;

    return copyWith(
      amount: calculationAmount,
      recargoPercentage: calculationRecargoPercentage,
      recargoAmount: calculatedRecargoAmount,
      totalAmount: calculatedTotalAmount,
    );
  }

  @override
  String toString() {
    return 'SplitPaymentItem{id: $id, providerId: $providerId, methodId: $methodId, amount: $amount, recargo: $recargoPercentage%, total: $totalAmount}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitPaymentItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}