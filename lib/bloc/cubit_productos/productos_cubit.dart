import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../calculos/calculo_iva.dart';
import '../../models/Producto_precio_stock.dart';
import '../../models/datos_facturacion_model.dart';
import '../../models/producto.dart';
import '../../models/user.dart';
import '../../services/user_repository.dart';

part 'productos_state.dart';

class ProductosCubit extends Cubit<ProductosState> {
  final UserRepository userRepository;

  ProductosCubit(this.userRepository, {required List<ProductoModel> currentListProductCubit})
      : super(ProductosState(currentListProductCubit: currentListProductCubit, categoriaIvaUser: 'Monotributo'));

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

      final String? barcode;
      if (data.containsKey('productoSeleccionado')) {
        final producto = data['productoSeleccionado'];
        barcode = producto.barcode;
      } else if (data.containsKey('productoConPrecioYStock')) {
        barcode = (data['productoConPrecioYStock'] as ProductoConPrecioYStock).producto?.barcode;
      } else {
        barcode = null;
      }

      final existingProductIndex = updatedList.indexWhere((p) => p.producto?.barcode == barcode);

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

      if (data.containsKey('productoSeleccionado')) {
        final productoSeleccionado = data['productoSeleccionado'];
        double precioLista = 0.0;
        if (productoSeleccionado.listasPrecios != null && productoSeleccionado.listasPrecios!.isNotEmpty) {
          precioLista = double.parse(productoSeleccionado.listasPrecios!.first.precioLista ?? '0');
        }

        try {
          ivaEncontrado = productosIvas.firstWhere(
                (iva) => iva.sucursalId.toString() == sucursalId.toString() && iva.productId.toString() == productoSeleccionado.id.toString(),
          ).iva;
        } catch (e) {
          ivaEncontrado = 0.0;
        }

        final resultadoIva = calcularIva(
          precioProducto: precioLista,
          alicuotaIva: ivaEncontrado!,
          condicionIva: condIva.toString(),
          relacionPrecioIva: relacionPrecioIva!,
          ivaProducto: ivaEncontrado,
        );

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

        updatedList.add(productoAgregar);
        emit(state.copyWith(productosSeleccionados: updatedList, precioTotal: !state.precioTotal));
      }
    } catch (e) {
      print('Error al agregar producto: $e');
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

  void actualizarPreciosConLista(Map<String, double> listaPrecios) {
    final updatedList = state.productosSeleccionados.map((producto) {
      final codigo = producto.producto?.barcode;
      if (listaPrecios.containsKey(codigo)) {
        final nuevoPrecio = listaPrecios[codigo];
        producto.precioLista = nuevoPrecio;
        producto.precioFinal = (nuevoPrecio ?? 0) * (producto.cantidad ?? 1);
      }
      return producto;
    }).toList();
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
