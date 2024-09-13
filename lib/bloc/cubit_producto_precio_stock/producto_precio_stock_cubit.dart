import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/Producto_precio_stock.dart';
import '../../services/user_repository.dart';
import '../cubit_login/login_cubit.dart';

part 'producto_precio_stock_state.dart';

class ProductosConPrecioYStockCubit extends Cubit<ProductosConPrecioYStockState> {
  final UserRepository userRepository;
  final LoginCubit loginCubit; // Inyectamos el cubit de autenticación

  ProductosConPrecioYStockCubit(this.userRepository, this.loginCubit)
      : super(ProductosConPrecioYStockState(productos: [], isLoading: false));

  Future<List<ProductoConPrecioYStock>> getProductosConPrecioYStock(int listaId) async {
    try {
      emit(state.copyWith(isLoading: true));

      // Obtenemos la sucursal del usuario desde el LoginCubit
      final sucursalUsuario = loginCubit.state.user?.sucursal;

      // Llamamos al repositorio pasándole la sucursal del usuario
      final list = await userRepository.fetchProductosConPrecioYStock(
        listaId: listaId,
        sucursalUsuario: loginCubit.state.user!.sucursal!, // Pasamos la sucursal para la consulta
      );

      emit(state.copyWith(productos: list, isLoading: false));
      return list;
    } catch (e) {
      print("Error al obtener productos con precio y stock: $e");
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
    return [];
  }
}