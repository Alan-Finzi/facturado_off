import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../helper/database_helper.dart';
import '../../models/payment_method.dart';
import '../../models/payment_provider.dart';

part 'payment_methods_state.dart';

/// Cubit para manejar el estado relacionado con los métodos de pago
class PaymentMethodsCubit extends Cubit<PaymentMethodsState> {
  final DatabaseHelper _databaseHelper;

  PaymentMethodsCubit({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
        super(PaymentMethodsInitial());

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
          final method = provider.metodosPago!.firstWhere(
                (m) => m.id == methodId,
            orElse: () => null as PaymentMethod,
          );
          if (method != null) {
            selectedMethod = method;
            break;
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
  void setPaymentType(bool isPartialPayment) {
    if (state is PaymentMethodsLoaded) {
      final currentState = state as PaymentMethodsLoaded;
      emit(currentState.copyWith(isPartialPayment: isPartialPayment));
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

  /// Calcula el monto del recargo
  double getRecargoAmount() {
    if (state is PaymentMethodsLoaded) {
      final currentState = state as PaymentMethodsLoaded;

      PaymentMethod? selectedMethod = _getSelectedMethod(currentState);
      if (selectedMethod != null && currentState.subtotalAmount > 0) {
        return (currentState.subtotalAmount * selectedMethod.recargo) / 100;
      }
    }

    return 0.0;
  }
}