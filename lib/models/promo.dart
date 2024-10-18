class Promo {
  final int? tipoPromo; // 1 para descuento en %, 2 para combos de productos
  final double? precioPromo; // Precio de la promo para tipo 2
  final String? nombrePromo; // Nombre recordable de la promo
  final int? comercioId; // ID del comercio donde se aplica la promo
  final bool? activo; // 1 si la promo está activa, 0 si no
  final bool? limitarVigencia; // 1 o 0, si se limita a una fecha determinada
  final DateTime? vigenciaDesde; // Fecha de inicio de la vigencia
  final DateTime? vigenciaHasta; // Fecha de finalización de la vigencia
  final bool? limitarCantidad; // Limita las cantidades de promos a vender
  final bool? eliminado; // 1 si la promo está eliminada, 0 si no

  Promo({
    this.tipoPromo,
    this.precioPromo,
    this.nombrePromo,
    this.comercioId,
    this.activo,
    this.limitarVigencia,
    this.vigenciaDesde,
    this.vigenciaHasta,
    this.limitarCantidad,
    this.eliminado,
  });

  // Método para crear una instancia de Promo desde un mapa de datos
  factory Promo.fromMap(Map<String, dynamic> map) {
    return Promo(
      tipoPromo: map['tipo_promo'],
      precioPromo: map['precio_promo'] != null ? map['precio_promo'].toDouble() : null,
      nombrePromo: map['nombre_promo'],
      comercioId: map['comercio_id'],
      activo: map['activo'] == 1,
      limitarVigencia: map['limitar_vigencia'] == 1,
      vigenciaDesde: map['vigencia_desde'] != null ? DateTime.parse(map['vigencia_desde']) : null,
      vigenciaHasta: map['vigencia_hasta'] != null ? DateTime.parse(map['vigencia_hasta']) : null,
      limitarCantidad: map['limitar_cantidad'] == 1,
      eliminado: map['eliminado'] == 1,
    );
  }

  // Método para convertir una instancia de Promo a un mapa de datos
  Map<String, dynamic> toMap() {
    return {
      'tipo_promo': tipoPromo,
      'precio_promo': precioPromo,
      'nombre_promo': nombrePromo,
      'comercio_id': comercioId,
      'activo': activo == true ? 1 : 0,
      'limitar_vigencia': limitarVigencia == true ? 1 : 0,
      'vigencia_desde': vigenciaDesde?.toIso8601String(),
      'vigencia_hasta': vigenciaHasta?.toIso8601String(),
      'limitar_cantidad': limitarCantidad == true ? 1 : 0,
      'eliminado': eliminado == true ? 1 : 0,
    };
  }
}
