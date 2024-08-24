part of 'productos_stock_sucursales_cubit.dart';

class ProductosStockSucursalesState extends Equatable {
  final List<ProductosStockSucursalesModel> currentList;

  ProductosStockSucursalesState({required this.currentList});

  ProductosStockSucursalesState copyWith({List<ProductosStockSucursalesModel>? currentList}) {
    return ProductosStockSucursalesState(
      currentList: currentList ?? this.currentList,
    );
  }

  @override
  List<Object?> get props => [currentList];
}