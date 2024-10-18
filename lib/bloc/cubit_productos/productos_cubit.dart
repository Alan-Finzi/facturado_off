import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/Producto_precio_stock.dart';
import '../../models/producto.dart';
import '../../services/user_repository.dart';

part 'productos_state.dart';

// productos_cubit.dart
class ProductosCubit extends Cubit<ProductosState> {
  final UserRepository userRepository;

  ProductosCubit(this.userRepository, {required List<ProductoModel> currentListProductCubit})
      : super(ProductosState(currentListProductCubit: currentListProductCubit));

  // Método para obtener la lista de productos desde la base de datos
  Future<void> getProductsBD() async {
    try {
      final listProduct = await userRepository.fetchProductos();
      if (listProduct.isNotEmpty) {
        emit(ProductosState(
          currentListProductCubit: listProduct,
          filteredListProductCubit: listProduct,
          categorias: ['Todas las categorías'] + _extractCategorias(listProduct),
        ));
      }
    } catch (e) {
      print("Error al obtener productos: $e");
    }
  }

  void filterProducts(String query, String categoriaSeleccionada) {
    final originalList = state.currentListProductCubit;
    final categoria = categoriaSeleccionada.isNotEmpty ? categoriaSeleccionada : 'Todas las categorías';

    final filteredList = originalList.where((producto) {
      final matchesQuery = query.isEmpty ||
          (producto.name?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
          (producto.barcode?.toLowerCase().contains(query.toLowerCase()) ?? false);
      final matchesCategoria = categoria == 'Todas las categorías' ||
          producto.tipoProducto == categoria;
      return matchesQuery && matchesCategoria;
    }).toList();

    emit(state.copyWith(filteredListProductCubit: filteredList, categoriaSeleccionada: categoria));
  }

  void setCategoriaSeleccionada(String categoria) {
    filterProducts('', categoria);
  }



  void agregarProducto(Map<String, dynamic> producto) {
    final updatedList = List<Map<String, dynamic>>.from(state.productosSeleccionados);
    final existingProductIndex = updatedList.indexWhere((item) => item['codigo'] == producto['codigo']);

    if (existingProductIndex >= 0) {
      updatedList[existingProductIndex]['cantidad'] += 1;
    } else {
      updatedList.add({
        'codigo': producto['codigo'],
        'nombre': producto['nombre'],
        'precio': producto['precio'],
        'precioTotal': producto['precio'],
        'cantidad': 1,
        'promoName': 'Promo',
        'iva': 0,
        'stock': 1,
      });
    }

    emit(state.copyWith(productosSeleccionados: updatedList));
  }

  void eliminarProducto(int index) {
    final updatedList = List<Map<String, dynamic>>.from(state.productosSeleccionados);
    updatedList.removeAt(index);
    emit(state.copyWith(productosSeleccionados: updatedList));
  }

  void incrementarCantidad(int index) {
    final updatedList = List<Map<String, dynamic>>.from(state.productosSeleccionados);
    updatedList[index]['cantidad']++;
    actualizarPrecioTotal(index);
    emit(state.copyWith(productosSeleccionados: updatedList));
  }

  void decrementarCantidad(int index) {
    final updatedList = List<Map<String, dynamic>>.from(state.productosSeleccionados);
    if (updatedList[index]['cantidad'] > 1) {
      updatedList[index]['cantidad']--;
      actualizarPrecioTotal(index);
      emit(state.copyWith(productosSeleccionados: updatedList));
    }
  }

  void precioTotal(int index, int cantidad) {
    final updatedList = List<Map<String, dynamic>>.from(state.productosSeleccionados);
    if (cantidad > 0) {
      updatedList[index]['cantidad'] = cantidad;
      updatedList[index]['precioTotal'] = updatedList[index]['precio'] * cantidad;
      emit(state.copyWith(productosSeleccionados: updatedList, precioTotal: !state.precioTotal));
    }
  }

  void actualizarPrecioTotal(int index) {
    final updatedList = List<Map<String, dynamic>>.from(state.productosSeleccionados);
    final cantidad = updatedList[index]['cantidad'];
    updatedList[index]['precioTotal'] = updatedList[index]['precio'] * cantidad;
    emit(state.copyWith(productosSeleccionados: updatedList, precioTotal: !state.precioTotal));
  }

   actualizarPreciosConLista(Map<String, double> listaPrecios) {
    final updatedList = state.productosSeleccionados.map((producto) {
      final codigo = producto['codigo'];
      if (listaPrecios.containsKey(codigo)) {
        final nuevoPrecio = listaPrecios[codigo];
        return {
          ...producto,
          'precio': nuevoPrecio,
          'precioTotal': nuevoPrecio! * producto['cantidad'],
        };
      }
      return producto;
    }).toList();

    emit(state.copyWith(productosSeleccionados: updatedList, precioTotal: !state.precioTotal));
  }
  void actualizarPrecioTotalProducto(Map<String, dynamic> producto) {
    final updatedList = List<Map<String, dynamic>>.from(state.productosSeleccionados);

    // Encuentra el índice del producto en la lista
    final index = updatedList.indexWhere((item) => item['codigo'] == producto['codigo']);

    if (index != -1) {
      // Recupera la cantidad actual
      final cantidad = updatedList[index]['cantidad'] as int;

      // Actualiza el precio total del producto
      updatedList[index]['precioTotal'] = (producto['precio'] as double) * cantidad;

      // Emitir el nuevo estado con la lista actualizada
      emit(state.copyWith(productosSeleccionados: updatedList, precioTotal: !state.precioTotal));
    } else {
      // Manejo del caso cuando el producto no se encuentra en la lista (opcional)
      // Puedes agregar una notificación o log para el producto no encontrado
      print('Producto no encontrado en la lista de seleccionados');
    }
  }

  void cambiarCantidad(int index, int cambio) {
    final updatedList = List<Map<String, dynamic>>.from(state.productosSeleccionados);
    final nuevaCantidad = updatedList[index]['cantidad'] + cambio;

    if (nuevaCantidad < 1) return; // Evita cantidades negativas

    // Actualiza la cantidad y el precio total del producto
    updatedList[index]['cantidad'] = nuevaCantidad;
    updatedList[index]['precioTotal'] = updatedList[index]['precio'] * nuevaCantidad;

    // Emite un nuevo estado con la lista actualizada
    emit(state.copyWith(productosSeleccionados: updatedList, precioTotal: !state.precioTotal));
  }

  static List<String> _extractCategorias(List<ProductoModel> productos) {
    return productos.map((producto) => producto.tipoProducto.toString() ?? 'Sin categoría').toSet().toList();
  }

   actualizarPreciosDeProductosSeleccionados(
      List<Map<String, dynamic>> productosSeleccionados,
      List<ProductoConPrecioYStock> listaPrecios) {

    final updatedList = productosSeleccionados.map((producto) {
      final codigoProducto = producto['codigo'];

      // Encuentra el producto en la lista de precios basado en el código
      final productoConNuevoPrecio = listaPrecios.firstWhere(
              (p) => p.producto.barcode == codigoProducto);

      if (productoConNuevoPrecio != null) {
        final nuevoPrecio = productoConNuevoPrecio.precioLista;

        // Actualizar el producto con el nuevo precio y recalcular el precio total
        return {
          ...producto,
          'precio': nuevoPrecio,
          'precioTotal': nuevoPrecio! * producto['cantidad'],
        };
      }
      return producto; // Si no se encuentra un nuevo precio, retorna el producto sin cambios
    }).toList();

    // Emitir la nueva lista de productos seleccionados actualizados
    emit(state.copyWith(productosSeleccionados: updatedList, precioTotal: !state.precioTotal));
  }
}
