

part of 'producto_precio_stock_cubit.dart';



class ProductosConPrecioYStockState extends Equatable {
  final List<ProductoConPrecioYStock> productos;
  final bool isLoading;
  final String? errorMessage;

  ProductosConPrecioYStockState({
    required this.productos,
    this.isLoading = false,
    this.errorMessage,
  });

  ProductosConPrecioYStockState copyWith({
    List<ProductoConPrecioYStock>? productos,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProductosConPrecioYStockState(
      productos: productos ?? this.productos,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [productos, isLoading, errorMessage];
}
