import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../calculos/calculo_iva.dart';
import '../../models/Producto_precio_stock.dart';
import '../../models/datos_facturacion_model.dart';
import '../../models/producto.dart';
import '../../models/user.dart';
import '../../services/user_repository.dart';

part 'productos_state.dart';

/// Cubit encargado de gestionar el estado de los productos en la aplicación.
/// Maneja la lista de productos, filtrado, selección y cálculos de precios.
class ProductosCubit extends Cubit<ProductosState> {
  /// Repositorio para acceder a datos de productos desde la base de datos o API
  final UserRepository userRepository;

  /// Constructor que inicializa el Cubit con un estado inicial y el repositorio necesario
  /// @param userRepository Repositorio para acceso a datos
  /// @param currentListProductCubit Lista inicial de productos
  ProductosCubit(this.userRepository, {required List<ProductoModel> currentListProductCubit})
      : super(ProductosState(currentListProductCubit: currentListProductCubit, categoriaIvaUser: 'Monotributo'));

  /// Obtiene productos desde la base de datos y actualiza el estado
  /// Este método recupera todos los productos, inicializa las listas de productos y categorias
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
      // Considerar emitir un estado de error para notificar al UI
    }
  }

  /// Limpia la lista de productos seleccionados en el estado actual
  /// Utilizado cuando se cambia de cliente o se reinicia una venta
  void limpiarProductosSeleccionados() {
    emit(state.copyWith(productosSeleccionados: []));
  }

  void updateDatosFacturacion(List<DatosFacturacionModel> datosFacturacion) {
    emit(state.copyWith(datosFacturacionModel: datosFacturacion));
  }

  void updateCategoriaIvaUser(String categoriaIvaUser) {
    emit(state.copyWith(categoriaIvaUser: categoriaIvaUser));
  }
  
  void updateTipoFactura(String tipoFactura) {
    emit(state.copyWith(tipoFactura: tipoFactura));
  }
  
  void updateCajaSeleccionada(String cajaSeleccionada) {
    emit(state.copyWith(cajaSeleccionada: cajaSeleccionada));
  }
  
  void updateCanalVenta(String canalVenta) {
    emit(state.copyWith(canalVenta: canalVenta));
  }

  /// Filtra la lista de productos por texto de búsqueda y categoría
  /// @param query Texto para buscar en nombre o código de barras
  /// @param categoriaSeleccionada Categoría para filtrar productos
  void filterProducts(String query, String categoriaSeleccionada) {
    final originalList = state.currentListProductCubit;
    final categoria = categoriaSeleccionada.isNotEmpty ? categoriaSeleccionada : 'Todas las categorías';

    // Filtrado por nombre, código de barras y categoría
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

  /// Agrega un producto a la lista de productos seleccionados o incrementa su cantidad
  /// @param data Datos del producto a agregar, puede contener 'productoSeleccionado' o 'productoConPrecioYStock'
  Future<void> agregarProducto(Map<String, dynamic> data) async {
    try {
      final user = User.currencyUser;
      if (user == null) {
        print('Error: Usuario no autenticado.');
        return;
      }

      // Determinar la sucursal activa
      final sucursalId = user.comercioId == 1 ? user.sucursal : user.comercioId;
      
      // Obtener datos necesarios para el cálculo de IVA
      final productosIvas = await userRepository.fetchProductosIvas();
      final condIva = state.datosFacturacionModel?[0].condicionIva;
      final relacionPrecioIva = state.datosFacturacionModel?[0].relacionPrecioIva;

      ProductoConPrecioYStock? productoAgregar;
      double? ivaEncontrado = 0.0;

      // Crear una copia de la lista actual para modificarla
      final updatedList = List<ProductoConPrecioYStock>.from(state.productosSeleccionados);

      // Obtener el código de barras del producto a agregar
      final String? barcode;
      if (data.containsKey('productoSeleccionado')) {
        final producto = data['productoSeleccionado'];
        barcode = producto.barcode;
      } else if (data.containsKey('productoConPrecioYStock')) {
        barcode = (data['productoConPrecioYStock'] as ProductoConPrecioYStock).producto?.barcode;
      } else {
        barcode = null;
      }

      // Verificar si el producto ya está en la lista
      final existingProductIndex = updatedList.indexWhere((p) => p.producto?.barcode == barcode);

      // Si el producto ya existe, incrementar cantidad y recalcular precio
      if (existingProductIndex >= 0) {
        final existingProduct = updatedList[existingProductIndex];
        existingProduct.cantidad = (existingProduct.cantidad ?? 0.0) + 1.0;
        existingProduct.precioFinal = calcularPrecioFinalConIva(
          precioProducto: existingProduct.precioLista ?? 0.0,
          iva: existingProduct.iva ?? 0.0,
          cantidad: existingProduct.cantidad ?? 1.0,
        );

        emit(state.copyWith(productosSeleccionados: updatedList, precioTotal: !state.precioTotal));
        return;
      }

      // Si es un producto nuevo, agregarlo a la lista
      if (data.containsKey('productoSeleccionado')) {
        final productoSeleccionado = data['productoSeleccionado'];
        
        // Obtener el precio de lista del producto
        double precioLista = 0.0;
        if (productoSeleccionado.listasPrecios != null && productoSeleccionado.listasPrecios!.isNotEmpty) {
          precioLista = double.parse(productoSeleccionado.listasPrecios!.first.precioLista ?? '0');
        }

        // Buscar el IVA correspondiente al producto
        try {
          ivaEncontrado = productosIvas.firstWhere(
                (iva) => iva.sucursalId.toString() == sucursalId.toString() && iva.productId.toString() == productoSeleccionado.id.toString(),
          ).iva;
        } catch (e) {
          // Si no se encuentra, usar 0.0 como valor predeterminado
          ivaEncontrado = 0.0;
        }

        // Calcular IVA según condición fiscal del cliente
        final resultadoIva = calcularIva(
          precioProducto: precioLista,
          alicuotaIva: ivaEncontrado!,
          condicionIva: condIva.toString(),
          relacionPrecioIva: relacionPrecioIva!,
          ivaProducto: ivaEncontrado,
        );

        // Crear objeto de producto con precio y stock
        productoAgregar = ProductoConPrecioYStock(
          datum: productoSeleccionado,
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

        // Agregar el producto a la lista y emitir el nuevo estado
        updatedList.add(productoAgregar);
        emit(state.copyWith(productosSeleccionados: updatedList, precioTotal: !state.precioTotal));
      }
    } catch (e) {
      print('Error al agregar producto: $e');
      // Considerar emitir un estado de error para mostrar en UI
    }
  }

  double calcularPrecioFinalConIva({required double precioProducto, required double iva, required double cantidad}) {
    return (precioProducto * cantidad) * (1 + iva);
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
    actualizarPrecioTotal(index, cantidadActual);
    emit(state.copyWith(productosSeleccionados: updatedList));
  }

  void decrementarCantidad(int index) {
    final updatedList = List<ProductoConPrecioYStock>.from(state.productosSeleccionados);
    if (updatedList[index].cantidad! > 1) {
      double? cantidadActual = updatedList[index].cantidad;
      updatedList[index].cantidad = (updatedList[index].cantidad ?? 0) - 1;
      actualizarPrecioTotal(index, cantidadActual);
      emit(state.copyWith(productosSeleccionados: updatedList));
    }
  }

  void actualizarPrecioTotal(int index, double? cantidadActual) {
    final updatedList = List<ProductoConPrecioYStock>.from(state.productosSeleccionados);
    double precioUnitario = updatedList[index].precioFinal! / cantidadActual!;
    final cantidad = updatedList[index].cantidad;
    updatedList[index].precioFinal = precioUnitario * cantidad!;
    emit(state.copyWith(productosSeleccionados: updatedList, precioTotal: !state.precioTotal));
  }

  /// Actualiza los precios de los productos seleccionados según una nueva lista de precios
  /// @param listaPrecios Mapa de códigos de barras a nuevos precios
  /// Este método es clave para sincronizar los cambios de lista de precios cuando se cambia de cliente
  void actualizarPreciosConLista(Map<String, double> listaPrecios) {
    final updatedList = state.productosSeleccionados.map((producto) {
      final codigo = producto.producto?.barcode;
      if (listaPrecios.containsKey(codigo)) {
        final nuevoPrecio = listaPrecios[codigo];
        producto.precioLista = nuevoPrecio;
        // Recalcular el precio final con la cantidad actual
        producto.precioFinal = (nuevoPrecio ?? 0) * (producto.cantidad ?? 1);
      }
      return producto;
    }).toList();
    // Emitir nuevo estado con precios actualizados y flag de precio total activado
    emit(state.copyWith(productosSeleccionados: updatedList, precioTotal: true));
  }

  void actualizarPrecioTotalProducto(Map<String, dynamic> producto) {
    final updatedList = List<ProductoConPrecioYStock>.from(state.productosSeleccionados);
    final index = updatedList.indexWhere((item) => item.producto?.barcode == producto['codigo']);

    if (index != -1) {
      final productoExistente = updatedList[index];
      final nuevoPrecio = producto['precio'] as double;
      productoExistente.precioLista = nuevoPrecio;
      productoExistente.precioFinal = nuevoPrecio * (productoExistente.cantidad ?? 1);

      emit(state.copyWith(productosSeleccionados: updatedList, precioTotal: true));
    } else {
      print('Producto no encontrado en la lista de seleccionados');
    }
  }

  void cambiarCantidad(int index, int cambio) {
    final updatedList = List<ProductoConPrecioYStock>.from(state.productosSeleccionados);
    final nuevaCantidad = updatedList[index].cantidad! + cambio;

    if (nuevaCantidad < 1) return;

    double? cantidad = updatedList[index].cantidad;
    double? precioUnitario = updatedList[index].precioFinal! / cantidad!;
    updatedList[index].cantidad = nuevaCantidad;
    updatedList[index].precioFinal = precioUnitario * nuevaCantidad;

    emit(state.copyWith(productosSeleccionados: updatedList, precioTotal: !state.precioTotal));
  }

  static List<String> _extractCategorias(List<ProductoModel> productos) {
    return productos.map((producto) => producto.tipoProducto.toString()).toSet().toList();
  }

  void actualizarPreciosDeProductosSeleccionados(
      List<ProductoConPrecioYStock> productosSeleccionados,
      List<ProductoConPrecioYStock> listaPrecios) {

    final updatedList = productosSeleccionados.map((producto) {
      final int? productId = producto.producto?.id;

      final productoConNuevoPrecio = listaPrecios.firstWhere(
            (p) => p.producto?.id == productId,
        orElse: () => producto,
      );

      final double nuevoPrecio = productoConNuevoPrecio.precioLista ?? 0.0;
      producto.precioLista = nuevoPrecio;
      producto.precioFinal = nuevoPrecio * (producto.cantidad ?? 1);

      return producto;
    }).toList();

    emit(state.copyWith(productosSeleccionados: updatedList, precioTotal: true));
  }

  // Método adicional recuperado que se utilizaba antes:
  void precioTotal(int index, int cantidad) {
    final updatedList = List<ProductoConPrecioYStock>.from(state.productosSeleccionados);
    if (cantidad > 0) {
      updatedList[index].cantidad = cantidad.toDouble() ;
      updatedList[index].precioFinal = updatedList[index].precioLista! * cantidad;
      emit(state.copyWith(productosSeleccionados: updatedList, precioTotal: !state.precioTotal));
    }
  }

}
