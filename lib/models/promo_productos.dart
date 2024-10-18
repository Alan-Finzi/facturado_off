class PromoProducto {
  final String? nombrePromo; // Nombre de la promoción
  final int? promoId; // ID de la promoción
  final int? productId; // ID del producto asociado a la promo
  final String? referenciaVariacion; // Referencia de la variación asociada a la promo
  final int? cantidad; // Cantidad de ese producto en la promo
  final double? porcentajeDescuento; // Porcentaje de descuento que se aplica a este producto
  final int? comercioId; // ID del comercio
  final bool? activo; // 1 si el producto está activo en la promo, 0 si no
  final bool? eliminado; // 1 si el producto de la promo está eliminado, 0 si no

  PromoProducto({
    this.nombrePromo,
    this.promoId,
    this.productId,
    this.referenciaVariacion,
    this.cantidad,
    this.porcentajeDescuento,
    this.comercioId,
    this.activo,
    this.eliminado,
  });

  // Método para crear una instancia de PromoProducto desde un mapa de datos
  factory PromoProducto.fromMap(Map<String, dynamic> map) {
    return PromoProducto(
      nombrePromo: map['nombre_promo'],
      promoId: map['promo_id'],
      productId: map['product_id'],
      referenciaVariacion: map['referencia_variacion'],
      cantidad: map['cantidad'],
      porcentajeDescuento: map['porcentaje_descuento'] != null ? map['porcentaje_descuento'].toDouble() : null,
      comercioId: map['comercio_id'],
      activo: map['activo'] == 1,
      eliminado: map['eliminado'] == 1,
    );
  }

  // Método para convertir una instancia de PromoProducto a un mapa de datos
  Map<String, dynamic> toMap() {
    return {
      'nombre_promo': nombrePromo,
      'promo_id': promoId,
      'product_id': productId,
      'referencia_variacion': referenciaVariacion,
      'cantidad': cantidad,
      'porcentaje_descuento': porcentajeDescuento,
      'comercio_id': comercioId,
      'activo': activo == true ? 1 : 0,
      'eliminado': eliminado == true ? 1 : 0,
    };
  }
}
