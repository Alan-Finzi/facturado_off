import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../helper/database_helper.dart';
import '../../models/payment_method.dart';
import '../../models/payment_provider.dart';
import '../../models/split_payment_item.dart';
import '../../models/split_payment_collection.dart';

part 'payment_methods_state.dart';

/// Cubit para manejar el estado relacionado con los métodos de pago
class PaymentMethodsCubit extends Cubit<PaymentMethodsState> {
  final DatabaseHelper _databaseHelper;

  PaymentMethodsCubit({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
        super(PaymentMethodsInitial()) {
    // Precarga de proveedores y métodos de pago al inicializar
    _preloadPaymentProviders();
  }

  /// Precarga los proveedores y métodos de pago en segundo plano
  Future<void> _preloadPaymentProviders() async {
    try {
      final providers = await _databaseHelper.getPaymentProviders();
      if (providers.isNotEmpty && state is PaymentMethodsInitial) {
        emit(PaymentMethodsLoaded(
          providers: providers,
          selectedProviderId: providers.isNotEmpty ? providers.first.id : null,
          selectedMethodId: _getFirstMethodId(providers),
          totalAmount: 0.0,
          inputAmount: 0.0,
          isPartialPayment: false,
        ));
      }
    } catch (e) {
      print('Error en precarga de proveedores de pago: $e');
      // No emitir error para evitar interrumpir el flujo
    }
  }

  /// Carga todos los proveedores de pago con sus métodos asociados
  Future<void> loadPaymentProviders() async {
    try {
      emit(PaymentMethodsLoading());
      final providers = await _databaseHelper.getPaymentProviders();
      if (providers.isEmpty) {
        emit(PaymentMethodsEmpty());
      } else {
        emit(PaymentMethodsLoaded(
          providers: providers,
          selectedProviderId: providers.isNotEmpty ? providers.first.id : null,
          selectedMethodId: _getFirstMethodId(providers),
          totalAmount: 0.0, // Inicialmente sin monto
          inputAmount: 0.0, // Inicialmente sin monto ingresado
          isPartialPayment: false,
        ));
      }
    } catch (e) {
      emit(PaymentMethodsError(message: e.toString()));
    }
  }

  /// Obtiene el ID del primer método del primer proveedor, si existe
  int? _getFirstMethodId(List<PaymentProvider> providers) {
    if (providers.isEmpty) return null;
    if (providers.first.metodosPago == null || providers.first.metodosPago!.isEmpty) return null;
    return providers.first.metodosPago!.first.id;
  }

  /// Cambia el proveedor de pago seleccionado
  void selectPaymentProvider(int providerId) {
    if (state is PaymentMethodsLoaded) {
      final currentState = state as PaymentMethodsLoaded;
      final provider = currentState.providers.firstWhere(
            (p) => p.id == providerId,
        orElse: () => throw Exception('Proveedor no encontrado'),
      );

      final firstMethodId = provider.metodosPago?.isNotEmpty == true
          ? provider.metodosPago!.first.id
          : null;

      emit(currentState.copyWith(
        selectedProviderId: providerId,
        selectedMethodId: firstMethodId,
      ));
    }
  }

  /// Cambia el método de pago seleccionado
  void selectPaymentMethod(int methodId) {
    if (state is PaymentMethodsLoaded) {
      final currentState = state as PaymentMethodsLoaded;

      // Buscar el método seleccionado para obtener el recargo
      PaymentMethod? selectedMethod;
      for (final provider in currentState.providers) {
        if (provider.metodosPago != null) {
          try {
            final method = provider.metodosPago!.firstWhere(
                  (m) => m.id == methodId,
            );
            selectedMethod = method;
            break;
          } catch (e) {
            // No se encontró el método en este proveedor, continuar con el siguiente
            continue;
          }
        }
      }

      // Recalcular el total con el recargo del nuevo método
      double updatedTotalAmount = currentState.totalAmount;
      if (selectedMethod != null && currentState.subtotalAmount > 0) {
        final recargoAmount = (currentState.subtotalAmount * selectedMethod.recargo) / 100;
        updatedTotalAmount = currentState.subtotalAmount + recargoAmount;
      }

      emit(currentState.copyWith(
        selectedMethodId: methodId,
        totalAmount: updatedTotalAmount,
      ));
    }
  }

  /// Actualiza el monto subtotal y recalcula el total con el recargo
  ///
  /// subtotalAmount: Monto subtotal que puede incluir subtotal+IVA o ya tener aplicado descuento
  ///
  void updateSubtotalAmount(double subtotalAmount) {
    if (state is PaymentMethodsLoaded) {
      final currentState = state as PaymentMethodsLoaded;

      // Obtener el método de pago actual
      PaymentMethod? selectedMethod = _getSelectedMethod(currentState);

      // Calcular el nuevo total con recargo
      double totalAmount = subtotalAmount;
      if (selectedMethod != null && subtotalAmount > 0) {
        final recargoAmount = (subtotalAmount * selectedMethod.recargo) / 100;
        totalAmount = subtotalAmount + recargoAmount;
      }

      emit(currentState.copyWith(
        subtotalAmount: subtotalAmount,
        totalAmount: totalAmount,
      ));
    }
  }

  /// Actualiza el monto ingresado por el cliente
  void updateInputAmount(double inputAmount) {
    if (state is PaymentMethodsLoaded) {
      final currentState = state as PaymentMethodsLoaded;
      emit(currentState.copyWith(inputAmount: inputAmount));
    }
  }

  /// Actualiza el tipo de pago (total o parcial/dividido)
  /// Limpia los datos relacionados al cambiar de modo
  void setPaymentType(bool isPartialPayment) {
    if (state is PaymentMethodsLoaded) {
      final currentState = state as PaymentMethodsLoaded;

      // Valores para resetear según el modo de pago
      SplitPaymentCollection? updatedSplitPayments;
      double inputAmount = 0.0; // Resetear el monto ingresado al cambiar de modo

      // Si cambiamos a modo pago dividido
      if (isPartialPayment) {
        // Inicializar la colección siempre al cambiar a modo dividido
        updatedSplitPayments = SplitPaymentCollection(
          items: [],
          subtotalAmount: currentState.subtotalAmount,
        );
      } else {
        // Si cambiamos a modo total, resetear el monto de entrada
        inputAmount = 0.0;
      }

      emit(currentState.copyWith(
        isPartialPayment: isPartialPayment,
        inputAmount: inputAmount, // Resetear monto ingresado
        splitPayments: updatedSplitPayments, // Nueva colección o null
      ));
    }
  }

  /// Establece el monto del input igual al total calculado
  void setPayTotalAmount() {
    if (state is PaymentMethodsLoaded) {
      final currentState = state as PaymentMethodsLoaded;
      emit(currentState.copyWith(inputAmount: currentState.totalAmount));
    }
  }

  /// Obtiene el método de pago actualmente seleccionado
  PaymentMethod? _getSelectedMethod(PaymentMethodsLoaded state) {
    if (state.selectedMethodId == null || state.selectedProviderId == null) {
      return null;
    }

    for (final provider in state.providers) {
      if (provider.id == state.selectedProviderId && provider.metodosPago != null) {
        for (final method in provider.metodosPago!) {
          if (method.id == state.selectedMethodId) {
            return method;
          }
        }
      }
    }

    return null;
  }

  /// Valida el monto ingresado
  ///
  /// Retorna null si es válido o un mensaje de error si no es válido
  String? validateInputAmount() {
    if (state is PaymentMethodsLoaded) {
      final currentState = state as PaymentMethodsLoaded;

      if (currentState.inputAmount < currentState.totalAmount) {
        return 'El monto ingresado debe ser igual o mayor al total (incluye recargo).';
      }
    }

    return null;
  }

  /// Calcula el vuelto a entregar
  double getChangeAmount() {
    if (state is PaymentMethodsLoaded) {
      final currentState = state as PaymentMethodsLoaded;

      if (currentState.inputAmount > currentState.totalAmount) {
        return currentState.inputAmount - currentState.totalAmount;
      }
    }

    return 0.0;
  }

  /// Calcula el monto del recargo con manejo mejorado de errores y consistencia
  double getRecargoAmount() {
    if (state is PaymentMethodsLoaded) {
      final currentState = state as PaymentMethodsLoaded;

      try {
        // Depurar los datos iniciales
        print('== CALCULANDO RECARGO ==');
        print('Subtotal para recargo: \$${currentState.subtotalAmount.toStringAsFixed(2)}');
        print('Proveedor ID: ${currentState.selectedProviderId}');
        print('Método ID: ${currentState.selectedMethodId}');

        // Verificar si tenemos proveedor y método seleccionados
        if (currentState.selectedProviderId == null || currentState.selectedMethodId == null) {
          print('No hay proveedor o método seleccionado');
          return 0.0;
        }

        // Obtener método seleccionado de forma segura
        PaymentMethod? selectedMethod = _getSelectedMethod(currentState);

        if (selectedMethod != null) {
          print('Método encontrado: ${selectedMethod.nombre} con tasa de recargo: ${selectedMethod.recargo}%');
        } else {
          print('No se encontró un método de pago válido');
          return 0.0;
        }

        // Validar que tengamos un subtotal válido
        if (currentState.subtotalAmount <= 0) {
          print('Subtotal inválido o cero: ${currentState.subtotalAmount}');
          return 0.0;
        }

        // Calcular recargo con protección para valores inválidos
        final recargo = selectedMethod.recargo;
        if (recargo.isNaN || recargo.isInfinite) {
          print('Error: Valor de recargo inválido (${selectedMethod.recargo})');
          return 0.0;
        }

        // Calcular monto de recargo con valor limpio
        final recargoAmount = (currentState.subtotalAmount * recargo) / 100;
        print('Cálculo de recargo: ${currentState.subtotalAmount} * ${recargo}% / 100 = $recargoAmount');

        // Verificar que el resultado es válido
        if (recargoAmount.isNaN || recargoAmount.isInfinite || recargoAmount < 0) {
          print('Error: Cálculo de recargo inválido: $recargoAmount');
          return 0.0;
        }

        // Devolver valor redondeado a 2 decimales para consistencia
        final roundedValue = double.parse(recargoAmount.toStringAsFixed(2));
        print('Recargo final (redondeado): \$${roundedValue.toStringAsFixed(2)}');

        // Verificar si el recargo es mayor a cero antes de aplicarlo
        if (roundedValue > 0) {
          print('RECARGO APLICADO: \$${roundedValue.toStringAsFixed(2)} (${recargo}%)');
        } else {
          print('Recargo es cero, no se aplica');
        }

        return roundedValue;
      } catch (e) {
        print('Error al calcular recargo: $e');
        print('StackTrace: ${StackTrace.current}');
        // Fallar silenciosamente con valor por defecto
      }
    } else {
      print('Estado no es PaymentMethodsLoaded: ${state.runtimeType}');
    }

    return 0.0;
  }

  // ==== Métodos para Pago Dividido ====

  /// Agrega un nuevo item de pago dividido
  void addSplitPaymentItem() {
    if (state is PaymentMethodsLoaded) {
      final currentState = state as PaymentMethodsLoaded;

      // Crear un ID único para el nuevo item
      final uniqueId = _generateUniqueId();

      // Si hay providers, usar el primero como default
      final defaultProviderId = currentState.providers.isNotEmpty ? currentState.providers.first.id : null;

      // Obtener el primer método del proveedor seleccionado
      int? defaultMethodId;
      if (defaultProviderId != null) {
        final provider = currentState.providers.firstWhere(
          (p) => p.id == defaultProviderId,
          orElse: () => throw Exception('Proveedor no encontrado'),
        );
        defaultMethodId = provider.metodosPago?.isNotEmpty == true ? provider.metodosPago!.first.id : null;
      }

      // Obtener el recargo del método por defecto
      double recargoPercentage = 0.0;
      if (defaultProviderId != null && defaultMethodId != null) {
        for (final provider in currentState.providers) {
          if (provider.id == defaultProviderId && provider.metodosPago != null) {
            for (final method in provider.metodosPago!) {
              if (method.id == defaultMethodId) {
                recargoPercentage = method.recargo;
                break;
              }
            }
          }
        }
      }

      // Crear un nuevo item con valores por defecto
      final newItem = SplitPaymentItem(
        id: uniqueId,
        providerId: defaultProviderId,
        methodId: defaultMethodId,
        amount: 0.0,
        recargoPercentage: recargoPercentage,
        recargoAmount: 0.0,
        totalAmount: 0.0,
      );

      // Actualizar la colección de items
      final updatedCollection = currentState.splitPayments.addItem(newItem);

      // Emitir nuevo estado
      emit(currentState.copyWith(
        splitPayments: updatedCollection,
      ));
    }
  }

  /// Elimina un item de pago dividido
  void removeSplitPaymentItem(String itemId) {
    if (state is PaymentMethodsLoaded) {
      final currentState = state as PaymentMethodsLoaded;

      // Eliminar item de la colección
      final updatedCollection = currentState.splitPayments.removeItem(itemId);

      // Emitir nuevo estado
      emit(currentState.copyWith(
        splitPayments: updatedCollection,
      ));
    }
  }

  /// Actualiza el proveedor de un item de pago dividido
  void updateSplitItemProvider(String itemId, int providerId) {
    if (state is PaymentMethodsLoaded) {
      final currentState = state as PaymentMethodsLoaded;

      // Buscar el item a actualizar
      final itemToUpdate = currentState.splitPayments.items.firstWhere(
        (item) => item.id == itemId,
        orElse: () => throw Exception('Item no encontrado'),
      );

      // Buscar el primer método del proveedor seleccionado
      final provider = currentState.providers.firstWhere(
        (p) => p.id == providerId,
        orElse: () => throw Exception('Proveedor no encontrado'),
      );

      final methodId = provider.metodosPago?.isNotEmpty == true ? provider.metodosPago!.first.id : null;

      // Obtener recargo del método seleccionado
      double recargoPercentage = 0.0;
      if (methodId != null) {
        for (final method in provider.metodosPago ?? []) {
          if (method.id == methodId) {
            recargoPercentage = method.recargo;
            break;
          }
        }
      }

      // Actualizar el item con el nuevo proveedor y método
      final updatedItem = itemToUpdate.copyWith(
        providerId: providerId,
        methodId: methodId,
        recargoPercentage: recargoPercentage,
      );

      // Recalcular montos con el nuevo recargo
      final calculatedItem = updatedItem.calculateAmounts();

      // Actualizar la colección
      final updatedCollection = currentState.splitPayments.updateItem(calculatedItem);

      // Emitir nuevo estado
      emit(currentState.copyWith(
        splitPayments: updatedCollection,
      ));
    }
  }

  /// Actualiza el método de pago de un item de pago dividido
  void updateSplitItemMethod(String itemId, int methodId) {
    if (state is PaymentMethodsLoaded) {
      final currentState = state as PaymentMethodsLoaded;

      // Buscar el item a actualizar
      final itemToUpdate = currentState.splitPayments.items.firstWhere(
        (item) => item.id == itemId,
        orElse: () => throw Exception('Item no encontrado'),
      );

      // Buscar el método seleccionado para obtener su recargo
      PaymentMethod? selectedMethod;
      for (final provider in currentState.providers) {
        if (provider.id == itemToUpdate.providerId && provider.metodosPago != null) {
          try {
            final method = provider.metodosPago!.firstWhere(
              (m) => m.id == methodId,
            );
            selectedMethod = method;
            break;
          } catch (e) {
            // No se encontró el método en este proveedor
            continue;
          }
        }
      }

      // Si encontramos el método, aplicar su recargo
      double recargoPercentage = 0.0;
      if (selectedMethod != null) {
        recargoPercentage = selectedMethod.recargo;
      }

      // Actualizar el item con el nuevo método y recargo
      final updatedItem = itemToUpdate.copyWith(
        methodId: methodId,
        recargoPercentage: recargoPercentage,
      );

      // Recalcular montos con el nuevo recargo
      final calculatedItem = updatedItem.calculateAmounts();

      // Actualizar la colección
      final updatedCollection = currentState.splitPayments.updateItem(calculatedItem);

      // Emitir nuevo estado
      emit(currentState.copyWith(
        splitPayments: updatedCollection,
      ));
    }
  }

  /// Actualiza el monto de un item de pago dividido
  void updateSplitItemAmount(String itemId, double amount) {
    if (state is PaymentMethodsLoaded) {
      final currentState = state as PaymentMethodsLoaded;

      // Buscar el item a actualizar
      final itemToUpdate = currentState.splitPayments.items.firstWhere(
        (item) => item.id == itemId,
        orElse: () => throw Exception('Item no encontrado'),
      );

      // Actualizar el item con el nuevo monto
      final updatedItem = itemToUpdate.copyWith(amount: amount);

      // Recalcular montos con el mismo recargo pero nuevo monto
      final calculatedItem = updatedItem.calculateAmounts();

      // Actualizar la colección
      final updatedCollection = currentState.splitPayments.updateItem(calculatedItem);

      // Emitir nuevo estado
      emit(currentState.copyWith(
        splitPayments: updatedCollection,
      ));
    }
  }

  /// Genera un ID único para un nuevo item de pago
  String _generateUniqueId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return '${timestamp}_$random';
  }

  /// Valida si los montos de los items de pago dividido son válidos
  String? validateSplitPayments() {
    if (state is PaymentMethodsLoaded) {
      final currentState = state as PaymentMethodsLoaded;

      // Si no hay items, no es válido
      if (currentState.splitPayments.items.isEmpty) {
        return 'Debe agregar al menos un método de pago';
      }

      // Verificar que todos los items tengan método de pago seleccionado
      if (!currentState.splitPayments.items.every((item) => item.methodId != null && item.providerId != null)) {
        return 'Todos los pagos deben tener método y tipo de cobro seleccionados';
      }

      // Verificar que todos los items tengan monto mayor a cero
      if (!currentState.splitPayments.items.every((item) => item.amount > 0)) {
        return 'Todos los pagos deben tener un monto mayor a cero';
      }

      // Verificar que la suma de los montos sea igual al total
      final double totalPaid = currentState.splitPayments.items.fold(
        0.0,
        (sum, item) => sum + item.amount
      );

      final double targetTotal = currentState.subtotalAmount +
        currentState.splitPayments.items.fold(0.0, (sum, item) => sum + item.recargoAmount);

      if ((totalPaid - targetTotal).abs() > 0.01) {
        return 'La suma de los pagos (${totalPaid.toStringAsFixed(2)}) debe ser igual al total a pagar (${targetTotal.toStringAsFixed(2)})';
      }
    }

    return null;
  }
}