import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/Producto_precio_stock.dart';
import '../../models/producto.dart';
import '../../models/user.dart';
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


  void agregarProducto(Map<String, dynamic> data) async {
    try {
      final user = User.currencyUser;
      if (user == null) {
        print('Error: Usuario no autenticado.');
        return;
      }

      final sucursalId = user.comercioId == 1 ? user.sucursal : user.comercioId;

      // Obtener productosIvas si no se han cargado previamente
      final productosIvas = await userRepository.fetchProductosIvas();

      ProductoConPrecioYStock? productoAgregar;
      double? ivaEncontrado = 0.0;

      // Clonar la lista actual de productos seleccionados
      final updatedList = List<ProductoConPrecioYStock>.from(state.productosSeleccionados);

      // Verificar si el producto ya existe en la lista
      final existingProductIndex = updatedList.indexWhere((item) {
        if (data.containsKey('productoConPrecioYStock')) {
          return item.producto.barcode == (data['productoConPrecioYStock'] as ProductoConPrecioYStock).producto.barcode;
        } else if (data.containsKey('producto')) {
          return item.producto.barcode == (data['producto']['barcode'] as String?);
        }
        return false;
      });

      if (existingProductIndex >= 0) {
        // Producto ya existe: actualizar cantidad y precio final
        final existingProduct = updatedList[existingProductIndex];
        existingProduct.cantidad = (existingProduct.cantidad ?? 0) + 1;
        existingProduct.precioFinal = (existingProduct.precioLista ?? 0.0) * existingProduct.cantidad!;

        emit(state.copyWith(
          productosSeleccionados: updatedList,
          precioTotal: !state.precioTotal,
        ));
        print('Producto actualizado: ${existingProduct.producto.name}');
        return;
      }

      // Procesar el nuevo producto
      if (data.containsKey('productoConPrecioYStock')) {
        productoAgregar = data['productoConPrecioYStock'] as ProductoConPrecioYStock;
        ivaEncontrado = productosIvas
            .firstWhere(
              (iva) => iva.sucursalId.toString() == sucursalId.toString() &&
              iva.productId.toString() == productoAgregar!.producto.id.toString(),
        )
            ?.iva ?? 0.0;
        productoAgregar.iva = ivaEncontrado;
      } else if (data.containsKey('producto')) {
        final producto = ProductoModel.fromMap(data['producto'] as Map<String, dynamic>);
        final double? precioLista = data['precio_lista'] as double?;
        final double cantidadInicial = (data['cantidad'] as double?) ?? 0.0;

        ivaEncontrado = productosIvas
            .firstWhere(
              (iva) => iva.sucursalId.toString() == sucursalId.toString() &&
              iva.productId.toString() == producto.id.toString(),
        )
            ?.iva ?? 0.0;

        productoAgregar = ProductoConPrecioYStock(
          producto: producto,
          precioLista: precioLista,
          iva: ivaEncontrado,
          cantidad: cantidadInicial,
          precioFinal: (precioLista ?? 0.0) * cantidadInicial,
        );
      } else {
        print('Error: Datos inválidos para procesar el producto.');
        return;
      }

      // Agregar el nuevo producto a la lista
      productoAgregar.cantidad = 1;
      productoAgregar.precioFinal = (productoAgregar.precioLista ?? 0.0) * productoAgregar.cantidad!;
      updatedList.add(productoAgregar);

      emit(state.copyWith(
        productosSeleccionados: updatedList,
        precioTotal: !state.precioTotal,
      ));
      print('Producto agregado: ${productoAgregar.producto.name}');
    } catch (e) {
      print('Error al agregar el producto: $e');
    }
  }


  void eliminarProducto(int index) {
    final updatedList = List<ProductoConPrecioYStock>.from(state.productosSeleccionados);
    updatedList.removeAt(index);
    emit(state.copyWith(productosSeleccionados: updatedList));
  }

  void incrementarCantidad(int index) {
    final updatedList = List<ProductoConPrecioYStock>.from(state.productosSeleccionados);
    updatedList[index].cantidad = (updatedList[index].cantidad ?? 0) + 1;
    actualizarPrecioTotal(index);
    emit(state.copyWith(productosSeleccionados: updatedList));
  }

  void decrementarCantidad(int index) {
    final updatedList = List<ProductoConPrecioYStock>.from(state.productosSeleccionados);
    if (updatedList[index].cantidad! > 1) {
      updatedList[index].cantidad = (updatedList[index].cantidad ?? 0) - 1;
      actualizarPrecioTotal(index);
      emit(state.copyWith(productosSeleccionados: updatedList));
    }
  }

  void precioTotal(int index, double cantidad) {
    final updatedList = List<ProductoConPrecioYStock>.from(state.productosSeleccionados);
    if (cantidad > 0) {
      updatedList[index].cantidad = cantidad;
      updatedList[index].precioFinal = updatedList[index].precioFinal! * cantidad;
      emit(state.copyWith(productosSeleccionados: updatedList, precioTotal: !state.precioTotal));
    }
  }

  void actualizarPrecioTotal(int index) {
    final updatedList = List<ProductoConPrecioYStock>.from(state.productosSeleccionados);
    final cantidad = updatedList[index].cantidad;
    updatedList[index].precioFinal = updatedList[index].precioLista! * cantidad!;
    emit(state.copyWith(productosSeleccionados: updatedList, precioTotal: !state.precioTotal));
  }

  void actualizarPreciosConLista(Map<String, double> listaPrecios) {
    // Clonar la lista actual de productos seleccionados y actualizar los precios
    final updatedList = state.productosSeleccionados.map((producto) {
      final codigo = producto.producto.barcode;

      if (listaPrecios.containsKey(codigo)) {
        final nuevoPrecio = listaPrecios[codigo];

        // Actualizar las propiedades del producto
        producto.precioLista = nuevoPrecio;
        producto.precioFinal = (nuevoPrecio ?? 0) * (producto.cantidad ?? 1);
      }
      return producto; // Si no hay precio en la lista, se deja sin cambios
    }).toList();

    // Calcular el nuevo precio total de todos los productos seleccionados


    // Emitir el nuevo estado
    emit(state.copyWith(productosSeleccionados: updatedList, precioTotal: true));
  }

  void actualizarPrecioTotalProducto(Map<String, dynamic> producto) {
    // Clonar la lista actual de productos seleccionados
    final updatedList = List<ProductoConPrecioYStock>.from(state.productosSeleccionados);

    // Encuentra el índice del producto en la lista
    final index = updatedList.indexWhere((item) => item.producto.barcode == producto['codigo']);

    if (index != -1) {
      // Recupera el producto existente
      final productoExistente = updatedList[index];

      // Recupera el nuevo precio del producto desde el parámetro
      final nuevoPrecio = producto['precio'] as double;

      // Actualiza directamente las propiedades del producto
      productoExistente.precioLista = nuevoPrecio;
      productoExistente.precioFinal = nuevoPrecio * (productoExistente.cantidad ?? 1);

      // Emitir el nuevo estado con la lista actualizada
      final nuevoPrecioTotal = updatedList.fold<double>(
        0,
            (total, producto) => total + (producto.precioFinal ?? 0),
      );

      emit(state.copyWith(productosSeleccionados: updatedList, precioTotal: true));
    } else {
      // Manejo del caso cuando el producto no se encuentra en la lista
      print('Producto no encontrado en la lista de seleccionados');
    }
  }

  void cambiarCantidad(int index, int cambio) {
    final updatedList = List<ProductoConPrecioYStock>.from(state.productosSeleccionados);
    final nuevaCantidad = updatedList[index].cantidad! + cambio;

    if (nuevaCantidad < 1) return; // Evita cantidades negativas

    // Actualiza la cantidad y el precio total del producto
    updatedList[index].cantidad = nuevaCantidad;
    updatedList[index].precioFinal = updatedList[index].precioLista! * nuevaCantidad;

    // Emite un nuevo estado con la lista actualizada
    emit(state.copyWith(productosSeleccionados: updatedList, precioTotal: !state.precioTotal));
  }

  static List<String> _extractCategorias(List<ProductoModel> productos) {
    return productos.map((producto) => producto.tipoProducto.toString() ?? 'Sin categoría').toSet().toList();
  }

  void actualizarPreciosDeProductosSeleccionados(
      List<ProductoConPrecioYStock> productosSeleccionados,
      List<ProductoConPrecioYStock> listaPrecios) {

    // Mapea la lista de productos seleccionados para actualizar sus precios
    final updatedList = productosSeleccionados.map((producto) {
      final codigoProducto = producto.producto.barcode;

      // Encuentra el producto en la lista de precios basado en el código
      final productoConNuevoPrecio = listaPrecios.firstWhere(
            (p) => p.producto.barcode == codigoProducto,

      );

      if (productoConNuevoPrecio != null) {
        final nuevoPrecio = productoConNuevoPrecio.precioLista;

        // Actualizar el producto con el nuevo precio y recalcular el precio total

        producto.precioLista = nuevoPrecio;
        producto.precioFinal = nuevoPrecio! * (producto.cantidad ?? 1);

      return producto;
      }

      // Si no se encuentra un nuevo precio, retorna el producto sin cambios
      return producto;
    }).toList();

    // Recalcular el precio total global después de actualizar los productos
    final nuevoPrecioTotal = updatedList.fold<double>(
      0,
          (total, producto) => total + (producto.precioFinal ?? 0),
    );

    // Emitir el nuevo estado con la lista actualizada y el precio total
    emit(state.copyWith(productosSeleccionados: updatedList, precioTotal: true));
  }

}
