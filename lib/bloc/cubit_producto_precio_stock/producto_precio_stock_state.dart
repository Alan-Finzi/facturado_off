

part of 'producto_precio_stock_cubit.dart';


class ProductosConPrecioYStockState extends Equatable {
  final List<ProductoConPrecioYStock> productos;
  final List<ProductoConPrecioYStock> filteredProductosConPrecioYStock; // Lista filtrada
  final bool isLoading;
  final String? errorMessage;

  ProductosConPrecioYStockState({
    required this.productos,
    this.filteredProductosConPrecioYStock = const [], // Inicializar como lista vacía
    this.isLoading = false,
    this.errorMessage,
  });

  ProductosConPrecioYStockState copyWith({
    List<ProductoConPrecioYStock>? productos,
    List<ProductoConPrecioYStock>? filteredProductosConPrecioYStock,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProductosConPrecioYStockState(
      productos: productos ?? this.productos,
      filteredProductosConPrecioYStock: filteredProductosConPrecioYStock ?? this.filteredProductosConPrecioYStock,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [productos, filteredProductosConPrecioYStock, isLoading, errorMessage];
}