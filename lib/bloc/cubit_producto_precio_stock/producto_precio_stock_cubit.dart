import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helper/database_helper.dart';
import '../../model_relacion/producto_stock.dart';
import '../../models/Producto_precio_stock.dart';
import '../../models/producto.dart';
import '../../models/productos_lista_precios_model.dart';
import '../../models/productos_maestro.dart';
import '../../models/productos_stock_sucursales.dart';
import '../../services/user_repository.dart';
import '../cubit_login/login_cubit.dart';

part 'producto_precio_stock_state.dart';
class ProductosMaestroCubit extends Cubit<ProductosMaestroState> {
  ProductosMaestroCubit() : super(ProductosMaestroState());

  Future<void> cargarProductosConPrecioYStock(int listaId, int sucursalId) async {
    emit(state.copyWith(isLoading: true));

    try {
      final productoResponse = await DatabaseHelper.instance.getProductoResponseBySucursalId(sucursalId, listaId);

      emit(state.copyWith(
        isLoading: false,
        productoResponse: productoResponse,

      ));

      // Filtrar datos inicialmente si es necesario
      filterProductosConPrecioYStock('', '');
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: 'Error al cargar productos: $e'));
    }
  }
  void filterProductosConPrecioYStock(String query, String categoriaName) {
    final productos = state.productoResponse?.data ?? [];

    final productosFiltrados = productos.where((producto) {
      final nombre = producto.nombre?.toLowerCase() ?? '';
      final codigo = producto.barcode?.toLowerCase() ?? '';
      final categoria = producto.categoriaName?.toLowerCase() ?? '';

      final matchesCategoria = categoriaName.isEmpty || categoria == categoriaName.toLowerCase();
      final matchesQuery = nombre.contains(query.toLowerCase()) || codigo.contains(query.toLowerCase());

      return matchesCategoria && matchesQuery;
    }).toList();

    emit(state.copyWith(filteredProductoResponse: ProductoResponse(data: productosFiltrados)));
  }
}