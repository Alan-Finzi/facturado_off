import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../calculos/calculo_iva.dart';
import '../../models/Producto_precio_stock.dart';
import '../../models/datos_facturacion_model.dart';
import '../../models/producto.dart';
import '../../models/user.dart';
import '../../services/user_repository.dart';

part 'productos_state.dart';

// productos_cubit.dart
class ProductosCubit extends Cubit<ProductosState> {
  final UserRepository userRepository;

  ProductosCubit(this.userRepository, {required List<ProductoModel> currentListProductCubit})
      : super(ProductosState(currentListProductCubit: currentListProductCubit,categoriaIvaUser: 'Monotributo'));

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

  // Método para limpiar los productos seleccionados
  void limpiarProductosSeleccionados() {
    emit(state.copyWith(productosSeleccionados: []));
  }

  // Método para actualizar los datos de facturación
  void updateDatosFacturacion(List<DatosFacturacionModel> datosFacturacion) {
    emit(state.copyWith(datosFacturacionModel: datosFacturacion));
  }

  void updateCategoriaIvaUser(String categoriaIvaUser) {
    emit(state.copyWith(categoriaIvaUser: categoriaIvaUser));
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

      final productosIvas = await userRepository.fetchProductosIvas();

      final condIva = state.datosFacturacionModel?[0].condicionIva;
      final relacionPrecioIva = state.datosFacturacionModel?[0].relacionPrecioIva;

      ProductoConPrecioYStock? productoAgregar;
      double? ivaEncontrado = 0.0;

      final updatedList = List<ProductoConPrecioYStock>.from(state.productosSeleccionados);

      // Obtener barcode del producto seleccionado
      final String? barcode;
      if (data.containsKey('productoSeleccionado')) {
        final producto = data['productoSeleccionado'];
        barcode = producto.barcode;
      } else if (data.containsKey('productoConPrecioYStock')) {
        barcode = (data['productoConPrecioYStock'] as ProductoConPrecioYStock).producto?.barcode;
      } else {
        barcode = null;
      }

      // Verificar si el producto ya existe
      final existingProductIndex = updatedList.indexWhere((p) => p.producto?.barcode == barcode);

      if (existingProductIndex >= 0) {
        final existingProduct = updatedList[existingProductIndex];
        existingProduct.cantidad = (existingProduct.cantidad ?? 0.0) + 1.0;
        existingProduct.precioFinal = calcularPrecioFinalConIva(
          precioProducto: existingProduct.precioLista ?? 0.0,
          iva: existingProduct.iva ?? 0.0,
          cantidad: existingProduct.cantidad ?? 1.0,
        );

        emit(state.copyWith(
          productosSeleccionados: updatedList,
          precioTotal: !state.precioTotal,
        ));
        print('Producto actualizado: ${existingProduct.producto?.name}');
        return;
      }

      // Procesar nuevo producto
      if (data.containsKey('productoSeleccionado')) {
        final productoSeleccionado = data['productoSeleccionado'];

        // Obtener precio lista
        double precioLista = 0.0;
        if (productoSeleccionado.listasPrecios != null && productoSeleccionado.listasPrecios!.isNotEmpty) {
          // Ajustar lógica para seleccionar lista de precio adecuada
          precioLista = double.parse(productoSeleccionado.listasPrecios!.first.precioLista ?? '0');
        }

        try {
          ivaEncontrado = productosIvas.firstWhere(
                (iva) =>
            iva.sucursalId.toString() == sucursalId.toString() &&
                iva.productId.toString() == productoSeleccionado.id.toString(),
          ).iva;
        } on StateError catch (e) {
          // Esto captura el error cuando no se encuentra ningún elemento
          print('Error al buscar el IVA: $e');
          // Puedes asignar un valor por defecto o manejar el error aquí
          ivaEncontrado = 0.0; // o null según tu lógica
        } catch (e) {
          // Esto captura cualquier otro tipo de excepción
          print('Error inesperado: $e');
          ivaEncontrado = 0.0; // o null según tu lógica
        }





        // Calcular IVA aplicable
        final resultadoIva = calcularIva(
          precioProducto: precioLista,
          alicuotaIva: ivaEncontrado!,
          condicionIva: condIva.toString(),
          relacionPrecioIva: relacionPrecioIva!,
          ivaProducto: ivaEncontrado,
        );
          print(resultadoIva);
        productoAgregar = ProductoConPrecioYStock(
          datum:productoSeleccionado ,
          precioLista: precioLista,
          iva: resultadoIva.porcentajeIva,
          cantidad: 1.0,
          precioFinal: calcularPrecioFinalConIva(
            precioProducto: precioLista,
            iva: resultadoIva.porcentajeIva,
            cantidad: 1.0,
          ),
          porcentajeIva: resultadoIva.porcentajeIva,
          detalleCalculoIva: resultadoIva.detalleCalculo,
        );

        updatedList.add(productoAgregar);
        emit(state.copyWith(
          productosSeleccionados: updatedList,
          precioTotal: !state.precioTotal,
        ));
        print('Producto agregado: ${productoSeleccionado.nombre}');
      } else {
        print('Error: Formato de producto no reconocido');
      }
    } catch (e) {
      print('Error al agregar producto: $e');
    }
  }

// Método para calcular el precio final con IVA
  double calcularPrecioFinalConIva({
    required double precioProducto,
    required double iva,
    required double cantidad,
  }) {
    return (precioProducto * cantidad) * (1 + iva); // Precio con IVA considerando la cantidad
  }



  void eliminarProducto(int index) {
    final updatedList = List<ProductoConPrecioYStock>.from(state.productosSeleccionados);
    updatedList.removeAt(index);
    emit(state.copyWith(productosSeleccionados: updatedList));
  }

  void incrementarCantidad(int index) {
    final updatedList = List<ProductoConPrecioYStock>.from(state.productosSeleccionados);
    double? cantidadActual = updatedList[index].cantidad;
    updatedList[index].cantidad = (updatedList[index].cantidad ?? 0) + 1;
    actualizarPrecioTotal(index,cantidadActual);
    emit(state.copyWith(productosSeleccionados: updatedList));
  }

  void decrementarCantidad(int index) {
    final updatedList = List<ProductoConPrecioYStock>.from(state.productosSeleccionados);
    if (updatedList[index].cantidad! > 1) {
      double? cantidaActaul=0;
      cantidaActaul =  updatedList[index].cantidad;
      updatedList[index].cantidad = (updatedList[index].cantidad ?? 0) - 1;
      actualizarPrecioTotal(index, cantidaActaul);
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

  void actualizarPrecioTotal(int index, double? CantidadActual) {
    final updatedList = List<ProductoConPrecioYStock>.from(state.productosSeleccionados);
    double precioP=0;
    precioP = (updatedList[index].precioFinal! / CantidadActual!)!;
    final cantidad = updatedList[index].cantidad;

    updatedList[index].precioFinal = precioP * cantidad!;
    emit(state.copyWith(productosSeleccionados: updatedList, precioTotal: !state.precioTotal));
  }

  void actualizarPreciosConLista(Map<String, double> listaPrecios) {
    // Clonar la lista actual de productos seleccionados y actualizar los precios
    final updatedList = state.productosSeleccionados.map((producto) {
      final codigo = producto.producto?.barcode;

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

// Encuentra el índice del producto en la lista usando el barcode
    final index = updatedList.indexWhere((item) => item.producto?.barcode == producto['codigo']);

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
    double? cantidad = updatedList[index].cantidad;
    double? precioProducto =  updatedList[index].precioFinal! / cantidad!;
    // Actualiza la cantidad y el precio total del producto
    updatedList[index].cantidad = nuevaCantidad;
    updatedList[index].precioFinal = precioProducto! * nuevaCantidad;

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
      // Se asume que 'producto' tiene la propiedad 'id'
      final int? productId = producto.producto?.id;

      // Encuentra el producto en la lista de precios basado en el productId
      final productoConNuevoPrecio = listaPrecios.firstWhere(
            (p) => p.producto?.id == productId,);

      if (productoConNuevoPrecio != null) {
        // Convertir el precio (que viene como String) a double
        final double nuevoPrecio =
            double.tryParse(productoConNuevoPrecio.precioLista.toString() ?? "0") ?? 0.0;

        // Actualiza las propiedades del producto
        producto.precioLista = nuevoPrecio;
        producto.precioFinal = nuevoPrecio * (producto.cantidad ?? 1);
      }

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
