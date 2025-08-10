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

    // Si la consulta está vacía, solo filtrar por categoría
    if (query.isEmpty) {
      final productosFiltrados = productos.where((producto) {
        final categoria = producto.categoriaName?.toLowerCase() ?? '';
        return categoriaName.isEmpty || categoria == categoriaName.toLowerCase();
      }).toList();
      
      emit(state.copyWith(filteredProductoResponse: ProductoResponse(data: productosFiltrados)));
      return;
    }
    
    // Dividir la consulta en palabras clave individuales
    final keywords = query.toLowerCase().split(' ')
      .where((keyword) => keyword.isNotEmpty) // Eliminar palabras vacías
      .toList();
    
    final productosFiltrados = productos.where((producto) {
      // Obtener los textos a buscar
      final nombre = producto.nombre?.toLowerCase() ?? '';
      final codigo = producto.barcode?.toLowerCase() ?? '';
      final categoria = producto.categoriaName?.toLowerCase() ?? '';
      
      // Verificar si coincide con la categoría
      final matchesCategoria = categoriaName.isEmpty || categoria == categoriaName.toLowerCase();
      
      // Si no coincide con la categoría, no seguir con la búsqueda
      if (!matchesCategoria) return false;
      
      // Verificar si el código contiene la consulta completa (útil para códigos de barras)
      if (codigo.contains(query.toLowerCase())) return true;
      
      // Para el nombre, verificar si todas las palabras clave están presentes
      // independientemente del orden
      final matchesNombre = keywords.every((keyword) => nombre.contains(keyword));
      

      return matchesNombre;

    }).toList();

    emit(state.copyWith(filteredProductoResponse: ProductoResponse(data: productosFiltrados)));
  }
}