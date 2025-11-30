import 'dart:math';
import 'package:facturador_offline/models/split_payment_item.dart';

/// Modelo que representa una colección de items de pago dividido
///
/// Administra el conjunto de métodos de pago y realiza cálculos agregados
/// como el total de todos los pagos, total de recargos, etc.
class SplitPaymentCollection {
  /// Lista de items de pago individuales
  final List<SplitPaymentItem> items;

  /// Monto subtotal de la venta (antes de recargos)
  final double subtotalAmount;

  const SplitPaymentCollection({
    required this.items,
    this.subtotalAmount = 0.0,
  });

  /// Constructor vacío con lista de items vacía
  factory SplitPaymentCollection.empty({double subtotalAmount = 0.0}) {
    return SplitPaymentCollection(
      items: [],
      subtotalAmount: subtotalAmount,
    );
  }

  /// Crea una copia de la colección con algunos campos actualizados
  SplitPaymentCollection copyWith({
    List<SplitPaymentItem>? items,
    double? subtotalAmount,
  }) {
    return SplitPaymentCollection(
      items: items ?? this.items,
      subtotalAmount: subtotalAmount ?? this.subtotalAmount,
    );
  }

  /// Agrega un nuevo item de pago a la colección
  SplitPaymentCollection addItem(SplitPaymentItem item) {
    return copyWith(
      items: [...items, item],
    );
  }

  /// Actualiza un item existente en la colección
  SplitPaymentCollection updateItem(SplitPaymentItem updatedItem) {
    final updatedItems = items.map((item) {
      return item.id == updatedItem.id ? updatedItem : item;
    }).toList();

    return copyWith(
      items: updatedItems,
    );
  }

  /// Elimina un item de la colección
  SplitPaymentCollection removeItem(String itemId) {
    return copyWith(
      items: items.where((item) => item.id != itemId).toList(),
    );
  }

  /// Calcula el total sumado de todos los items (incluyendo recargos)
  double get totalAmount {
    return items.fold(0.0, (sum, item) => sum + item.totalAmount);
  }

  /// Calcula el total de recargos de todos los items
  double get totalRecargoAmount {
    return items.fold(0.0, (sum, item) => sum + item.recargoAmount);
  }

  /// Calcula el monto restante por asignar a items de pago
  double get remainingAmount {
    final saleTotal = subtotalAmount + totalRecargoAmount;
    final assignedAmount = items.fold(0.0, (sum, item) => sum + item.amount);
    return max(0.0, saleTotal - assignedAmount);
  }

  /// Verifica si todos los items tienen métodos de pago seleccionados
  bool get allItemsHavePaymentMethods {
    return items.every((item) => item.providerId != null && item.methodId != null);
  }

  /// Verifica si la colección está vacía
  bool get isEmpty => items.isEmpty;

  /// Verifica si la colección tiene items
  bool get isNotEmpty => items.isNotEmpty;

  /// Obtiene la cantidad de items en la colección
  int get itemCount => items.length;

  /// Genera un ID único para un nuevo item
  String generateUniqueId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = random.nextInt(10000);
    return '${timestamp}_$randomPart';
  }
}