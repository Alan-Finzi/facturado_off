import 'package:facturador_offline/models/producto.dart';

class ProductoConPrecioYStock {
  final ProductoModel producto;
  final double? precioLista;
  final double? stock;
  final double? iva;
  final String? categoria;

  ProductoConPrecioYStock({
    required this.producto,
    this.precioLista,
    this.stock,
    this.iva,
    this.categoria
  });

  factory ProductoConPrecioYStock.fromMap(Map<String, dynamic> map) {
    return ProductoConPrecioYStock(
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
        categoria: map['categoryName']
    );
  }
}