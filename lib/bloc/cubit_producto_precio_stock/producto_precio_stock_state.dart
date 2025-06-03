

part of 'producto_precio_stock_cubit.dart';
class ProductosMaestroState extends Equatable {
  final ProductoResponse? productoResponse;
  final ProductoResponse? filteredProductoResponse;
  final bool isLoading;
  final String? errorMessage;

  ProductosMaestroState({
    this.productoResponse,
    this.filteredProductoResponse,
    this.isLoading = false,
    this.errorMessage,
  });

  ProductosMaestroState copyWith({
    ProductoResponse? productoResponse,
    ProductoResponse? filteredProductoResponse,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProductosMaestroState(
      productoResponse: productoResponse ?? this.productoResponse,
      filteredProductoResponse: filteredProductoResponse ?? this.filteredProductoResponse,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [productoResponse, filteredProductoResponse, isLoading, errorMessage];
}