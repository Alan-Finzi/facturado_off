import 'package:facturador_offline/models/producto.dart';
import 'package:facturador_offline/models/productos_maestro.dart';

import '../pages/page_home.dart';

class ProductoConPrecioYStock {
  final ProductoModel? producto;
  final Datum? datum;
  final ProductoResponse? productoDataMaestro;
  late final double? precioLista;
  late  double? porcentajeIva;
  final double? stock;
  late  double? iva;
  final String? categoria;
  late  double? cantidad;
  late  double? precioFinal;
  late  String? detalleCalculoIva;
  final String? promo;


  ProductoConPrecioYStock( {
    this.producto,
    this.datum,
    this.productoDataMaestro,
    this.precioLista,
    this.porcentajeIva,
    this.detalleCalculoIva,
    this.stock,
    this.iva,
    this.categoria,
      this.cantidad,
      this.precioFinal,
    this.promo,

  });

  factory ProductoConPrecioYStock.fromMap(Map<String, dynamic> map) {
    return ProductoConPrecioYStock(
        cantidad:map["cantidad"],
        precioFinal: map["precioFinal"],
      promo: map["promo"],
      producto: ProductoModel(
        id: map['id'],
        idProducto: map['producto_id'] as int,
        name: map['name'] as String?,
        tipoProducto: map['tipo_producto'],
        productoTipo: map['producto_tipo'],
        precioInterno: map['internalPrice'] != null ? map['internalPrice'] as double : null,  // Verificar si es nulo,
        barcode: map['barcode'] as String?,
        cost: map['cost'],
        alerts: map['alerts'],
        image: map['image'],
        categoryId: map['category_id'],
        marcaId: map['marca_id'],
        comercioId: map['comercio_id'],
        stockDescubierto: map['stock_descubierto'],
        proveedorId: map['proveedor_id'],
        eliminado: map['eliminado'],
        unidadMedida: map['unidad_medida'],
        wcProductId: map['wc_product_id'],
        wcPush: map['wc_push'],
        wcImage: map['wc_image'],
        etiquetas: map['etiquetas'],
        mostradorCanal: map['mostrador_canal'],
        ecommerceCanal: map['ecommerce_canal'],
        wcCanal: map['wc_canal'],
        descripcion: map['descripcion'],
        recetaId: map['receta_id'],
      ),
      precioLista: map['precio_lista'] as double?,
        stock: map['stock'] is int
            ? (map['stock'] as int).toDouble()  // Si es int, conviértelo a double
            : (map['stock'] is bool
            ? (map['stock'] ? 1.0 : 0.0)    // Si es bool, conviértelo a double 1.0 o 0.0
            : null),
      iva: map['iva'] as double?,
        categoria: map['categoryName'],


    );
  }

  // Método para convertir a Map<String, dynamic>
  Map<String, dynamic> toMap() {
      return {
          'producto': producto?.toMap(), // Usa el método toMap del modelo ProductoModelto
        "datum": datum?.toJson(),
          'precio_lista': precioLista,
          'stock': stock,
          'iva': iva,
          'categoryName': categoria,
          "precioFinal":precioFinal,
        "detalleCalculoIva":detalleCalculoIva,
        "cantidad":cantidad,
        "porcentajeIva":porcentajeIva,

      };
  }

}