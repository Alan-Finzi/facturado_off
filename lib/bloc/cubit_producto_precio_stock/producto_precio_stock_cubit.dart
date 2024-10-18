import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helper/database_helper.dart';
import '../../model_relacion/producto_stock.dart';
import '../../models/Producto_precio_stock.dart';
import '../../models/producto.dart';
import '../../models/productos_lista_precios_model.dart';
import '../../models/productos_stock_sucursales.dart';
import '../../services/user_repository.dart';
import '../cubit_login/login_cubit.dart';

part 'producto_precio_stock_state.dart';
class ProductosConPrecioYStockCubit extends Cubit<ProductosConPrecioYStockState> {
  final UserRepository userRepository;
  final LoginCubit loginCubit; // Inyectamos el cubit de autenticación

  ProductosConPrecioYStockCubit(this.userRepository, this.loginCubit)
      : super(ProductosConPrecioYStockState(productos: [], filteredProductosConPrecioYStock: [], isLoading: false));

  Future<List<ProductoConPrecioYStock>> cargarProductosConPrecioYStock(int listaId) async {
    emit(state.copyWith(isLoading: true, filteredProductosConPrecioYStock: []));

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');

    if (email == null) {
      emit(state.copyWith(isLoading: false, errorMessage: "No se encontró el correo en SharedPreferences", filteredProductosConPrecioYStock: [],));
      return [];
    }

    // Consultar al método getUserByEmail usando el email recuperado
    final user = await DatabaseHelper.instance.getUserByEmail(email);

    if (user == null || user.sucursal == null) {
      emit(state.copyWith(isLoading: false, errorMessage: "No se encontró el usuario o la sucursal", filteredProductosConPrecioYStock: [], ));
      return [];
    }

    // Actualizar el estado del loginCubit con la sucursal del usuario
    loginCubit.emit(loginCubit.state.copyWith(user: user));

    // Crear la lista de ProductoConPrecioYStock
    List<ProductoConPrecioYStock> productosConPrecioYStock = await userRepository.addQueryProductoCatalogo(listaId: listaId, sucursalId: user.sucursal!);

    emit(state.copyWith(isLoading: false, productos: productosConPrecioYStock, filteredProductosConPrecioYStock: [], ));

    // Filtrar productos después de cargarlos
    filterProductosConPrecioYStock('', ''); // Puedes ajustar los parámetros iniciales
    return productosConPrecioYStock;
  }

  void filterProductosConPrecioYStock(String query, String categoriaSeleccionada) {
    final originalList = state.productos;
    final categoria = categoriaSeleccionada.isNotEmpty ? categoriaSeleccionada : 'Todas las categorías';

    // Divide el query en palabras separadas por espacios
    final queryKeywords = query.toLowerCase().split(' ').where((keyword) => keyword.isNotEmpty).toList();

    final filteredList = originalList.where((productoConPrecioYStock) {
      // Verifica si el nombre o el código de barras contiene todas las palabras
      final matchesQuery = queryKeywords.isEmpty || queryKeywords.every((keyword) {
        final nameMatches = productoConPrecioYStock.producto.name?.toLowerCase().contains(keyword) ?? false;
        final barcodeMatches = productoConPrecioYStock.producto.barcode?.toLowerCase().contains(keyword) ?? false;
        return nameMatches || barcodeMatches;
      });

      final matchesCategoria = categoria == 'Todas las categorías' ||
          productoConPrecioYStock.categoria == categoria;

      return matchesQuery && matchesCategoria;
    }).toList();

    emit(state.copyWith(filteredProductosConPrecioYStock: filteredList));
  }
}
