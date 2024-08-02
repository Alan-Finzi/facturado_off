class ProductoModel {
  final String? name;
  final String? tipoProducto;
  final String? productoTipo;
  final double? precioInterno;
  final String? barcode;
  final double? cost;
  final String? image;
  final int? categoryId;
  final int? marcaId;
  final int? comercioId;
  final String? stockDescubierto;
  final int? proveedorId;
  final bool? eliminado;
  final int? unidadMedida;
  final int? wcProductId;
  final bool? wcPush;
  final String? wcImage;
  final String? etiquetas;
  final bool? mostradorCanal;
  final bool? ecommerceCanal;
  final bool? wcCanal;
  final String? descripcion;
  final int? recetaId;

  // Campos de la tabla 'productos_stock_sucursales'
  final int? stock;
  final int? stockReal;

  // Campos de la tabla 'productos_lista_precios'
  final double? precioLista;
  final int? listaId;

  // Campos de la tabla 'productos_ivas'
  final double? iva;

  ProductoModel({
    this.name,
    this.tipoProducto,
    this.productoTipo,
    this.precioInterno,
    this.barcode,
    this.cost,
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
    this.stock,
    this.stockReal,
    this.precioLista,
    this.listaId,
    this.iva,
  });

  // Método para crear un objeto Producto a partir de un JSON
  factory ProductoModel.fromJson(Map<String, dynamic> json) {
    return ProductoModel(
      name: json['name'],
      tipoProducto: json['tipo_producto'],
      productoTipo: json['producto_tipo'],
      precioInterno: json['precio_interno'],
      barcode: json['barcode'],
      cost: json['cost'],
      image: json['image'],
      categoryId: json['category_id'],
      marcaId: json['marca_id'],
      comercioId: json['comercio_id'],
      stockDescubierto: json['stock_descubierto'],
      proveedorId: json['proveedor_id'],
      eliminado: json['eliminado'] == 1,
      unidadMedida: json['unidad_medida'],
      wcProductId: json['wc_product_id'],
      wcPush: json['wc_push'] == 1,
      wcImage: json['wc_image'],
      etiquetas: json['etiquetas'],
      mostradorCanal: json['mostrador_canal'] == 1,
      ecommerceCanal: json['ecommerce_canal'] == 1,
      wcCanal: json['wc_canal'] == 1,
      descripcion: json['descripcion'],
      recetaId: json['receta_id'],
      stock: json['stock'],
      stockReal: json['stock_real'],
      precioLista: json['precio_lista'],
      listaId: json['lista_id'],
      iva: json['iva'],
    );
  }

  // Método para convertir un objeto Producto a JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'tipo_producto': tipoProducto,
      'producto_tipo': productoTipo,
      'precio_interno': precioInterno,
      'barcode': barcode,
      'cost': cost,
      'image': image,
      'category_id': categoryId,
      'marca_id': marcaId,
      'comercio_id': comercioId,
      'stock_descubierto': stockDescubierto,
      'proveedor_id': proveedorId,
      'eliminado': eliminado == true ? 1 : 0,
      'unidad_medida': unidadMedida,
      'wc_product_id': wcProductId,
      'wc_push': wcPush == true ? 1 : 0,
      'wc_image': wcImage,
      'etiquetas': etiquetas,
      'mostrador_canal': mostradorCanal == true ? 1 : 0,
      'ecommerce_canal': ecommerceCanal == true ? 1 : 0,
      'wc_canal': wcCanal == true ? 1 : 0,
      'descripcion': descripcion,
      'receta_id': recetaId,
      'stock': stock,
      'stock_real': stockReal,
      'precio_lista': precioLista,
      'lista_id': listaId,
      'iva': iva,
    };
  }
}

