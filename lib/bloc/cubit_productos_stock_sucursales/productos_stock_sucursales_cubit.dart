import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/productos_stock_sucursales.dart';
import '../../services/user_repository.dart';

part 'productos_stock_sucursales_state.dart';

class ProductosStockSucursalesCubit extends Cubit<ProductosStockSucursalesState> {
  final UserRepository userRepository;

  ProductosStockSucursalesCubit(this.userRepository)
      : super(ProductosStockSucursalesState(currentList: []));

  Future<void> getProductosStockSucursalesBD() async {
    try {
      final list = await userRepository.fetchProductosStockSucursales();
      emit(ProductosStockSucursalesState(currentList: list));
    } catch (e) {
      // Manejo de errores
      print("Error al obtener stock de productos en sucursales: $e");
    }
  }

  void addProductoStockSucursal(ProductosStockSucursalesModel productoStockSucursal) {
    final updatedList = List<ProductosStockSucursalesModel>.from(state.currentList);
    updatedList.add(productoStockSucursal);
    emit(state.copyWith(currentList: updatedList));
  }

  void removeProductoStockSucursal(int productId, int sucursalId, int almacenId) {
    final updatedList = state.currentList.where((item) =>
    item.productId != productId ||
        item.sucursalId != sucursalId ||
        item.almacenId != almacenId).toList();
    emit(state.copyWith(currentList: updatedList));
  }
}