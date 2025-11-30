part of 'payment_methods_cubit.dart';

/// Estados para el cubit de métodos de pago
abstract class PaymentMethodsState extends Equatable {
  const PaymentMethodsState();
}

/// Estado inicial antes de cualquier carga de datos
class PaymentMethodsInitial extends PaymentMethodsState {
  @override
  List<Object?> get props => [];
}

/// Estado durante la carga de datos
class PaymentMethodsLoading extends PaymentMethodsState {
  @override
  List<Object?> get props => [];
}

/// Estado cuando no hay métodos de pago disponibles
class PaymentMethodsEmpty extends PaymentMethodsState {
  @override
  List<Object?> get props => [];
}

/// Estado cuando los métodos de pago están cargados y disponibles
class PaymentMethodsLoaded extends PaymentMethodsState {
  /// Lista de proveedores de pago con sus métodos asociados
  final List<PaymentProvider> providers;

  /// ID del proveedor seleccionado actualmente
  final int? selectedProviderId;

  /// ID del método de pago seleccionado actualmente
  final int? selectedMethodId;

  /// Monto subtotal (sin recargo)
  final double subtotalAmount;

  /// Monto total (con recargo)
  final double totalAmount;

  /// Monto ingresado por el cliente
  final double inputAmount;

  /// Indicador si es pago parcial/dividido (true) o total (false)
  final bool isPartialPayment;

  /// Colección de items para el pago dividido (solo se usa cuando isPartialPayment = true)
  final SplitPaymentCollection splitPayments;

  const PaymentMethodsLoaded({
    required this.providers,
    this.selectedProviderId,
    this.selectedMethodId,
    this.subtotalAmount = 0.0,
    this.totalAmount = 0.0,
    this.inputAmount = 0.0,
    this.isPartialPayment = false,
    SplitPaymentCollection? splitPayments,
  }) : this.splitPayments = splitPayments ?? const SplitPaymentCollection(items: []);

  /// Crear una copia con algunos campos modificados
  PaymentMethodsLoaded copyWith({
    List<PaymentProvider>? providers,
    int? selectedProviderId,
    int? selectedMethodId,
    double? subtotalAmount,
    double? totalAmount,
    double? inputAmount,
    bool? isPartialPayment,
    SplitPaymentCollection? splitPayments,
  }) {
    return PaymentMethodsLoaded(
      providers: providers ?? this.providers,
      selectedProviderId: selectedProviderId ?? this.selectedProviderId,
      selectedMethodId: selectedMethodId ?? this.selectedMethodId,
      subtotalAmount: subtotalAmount ?? this.subtotalAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      inputAmount: inputAmount ?? this.inputAmount,
      isPartialPayment: isPartialPayment ?? this.isPartialPayment,
      splitPayments: splitPayments ?? this.splitPayments,
    );
  }

  @override
  List<Object?> get props => [
    providers,
    selectedProviderId,
    selectedMethodId,
    subtotalAmount,
    totalAmount,
    inputAmount,
    isPartialPayment,
    splitPayments,
  ];
}

/// Estado cuando ocurre un error al cargar los métodos de pago
class PaymentMethodsError extends PaymentMethodsState {
  final String message;

  const PaymentMethodsError({required this.message});

  @override
  List<Object?> get props => [message];
}