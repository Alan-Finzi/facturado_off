class ProductoModel {
  final int? id;
  final int? idProducto;
  final String? name;
  final String? tipoProducto;
  final String? productoTipo;
  final double? precioInterno;
  final String? barcode;
  final double? cost;
  final double? alerts;
  final String? image;
  final int? categoryId;
  final int? marcaId;
  final int? comercioId;
  final String? stockDescubierto;
  final int? proveedorId;
  final int? eliminado;
  final int? unidadMedida;
  final int? wcProductId;
  final int? wcPush;
  final String? wcImage;
  final String? etiquetas;
  final int? mostradorCanal;
  final int? ecommerceCanal;
  final int? wcCanal;
  final String? descripcion;
  final int? recetaId;

  ProductoModel({
    this.idProducto,
    this.id,
    this.name,
    this.tipoProducto,
    this.productoTipo,
    this.precioInterno,
    this.barcode,
    this.cost,
    this.alerts,
    this.image,
    this.categoryId,
    this.marcaId,
    this.comercioId,
    this.stockDescubierto,
    this.proveedorId,
    this.eliminado,
    this.unidadMedida,
    this.wcProductId,
    this.wcPush,
    this.wcImage,
    this.etiquetas,
    this.mostradorCanal,
    this.ecommerceCanal,
    this.wcCanal,
    this.descripcion,
    this.recetaId,
  });

  factory ProductoModel.fromMap(Map<String, dynamic> map) {
    return ProductoModel(
      id: map['id'],
      idProducto: map['idProducto'],
      name: map['name'],
      tipoProducto: map['tipo_producto'],
      productoTipo: map['producto_tipo'],
      precioInterno: map['precio_interno'],
      barcode: map['barcode'],
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'producto_id': idProducto,
      'name': name,
      'tipo_producto': tipoProducto,
      'producto_tipo': productoTipo,
      'precio_interno': precioInterno,
      'barcode': barcode,
      'cost': cost,
      'alerts': alerts,
      'image': image,
      'category_id': categoryId,
      'marca_id': marcaId,
      'comercio_id': comercioId,
      'stock_descubierto': stockDescubierto,
      'proveedor_id': proveedorId,
      'eliminado': eliminado,
      'unidad_medida': unidadMedida,
      'wc_product_id': wcProductId,
      'wc_push': wcPush,
      'wc_image': wcImage,
      'etiquetas': etiquetas,
      'mostrador_canal': mostradorCanal,
      'ecommerce_canal': ecommerceCanal,
      'wc_canal': wcCanal,
      'descripcion': descripcion,
      'receta_id': recetaId,
    };
  }
}