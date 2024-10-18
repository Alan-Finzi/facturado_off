class Sale {
  final int? nroVenta;
  final String? idVenta;
  final double? subtotal;
  final int? relacionPrecioIva;
  final double? alicuotaIva;
  final double? iva;
  final double? recargo;
  final double? alicuotaDescuento;
  final double? descuento;
  final double? descuentoPromo;
  final double? total;
  final int? items;
  final double? cash;
  final double? change;
  final double? deuda;
  final String? estadoPago;
  final String? status;
  final String? recordatorio; // En desuso
  final String? canalVenta;
  final int? comercioId;
  final int? metodoPago;
  final int? userId;
  final int? clienteId;
  final String? observaciones;
  final DateTime? fechaEntrega;
  final String? hojaRuta;
  final String? notaInterna;
  final int? caja;
  final String? tipoComprobante;
  final int? datosFacturacionId;

  Sale({
    this.nroVenta,
    this.idVenta,
    this.subtotal,
    this.relacionPrecioIva,
    this.alicuotaIva,
    this.iva,
    this.recargo,
    this.alicuotaDescuento,
    this.descuento,
    this.descuentoPromo,
    this.total,
    this.items,
    this.cash,
    this.change,
    this.deuda,
    this.estadoPago,
    this.status,
    this.recordatorio,
    this.canalVenta,
    this.comercioId,
    this.metodoPago,
    this.userId,
    this.clienteId,
    this.observaciones,
    this.fechaEntrega,
    this.hojaRuta,
    this.notaInterna,
    this.caja,
    this.tipoComprobante,
    this.datosFacturacionId,
  });

  // Método para crear una instancia de Sale desde un mapa de datos (por ejemplo, JSON o SQLite)
  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      nroVenta: map['nro_venta'],
      idVenta: map['idVenta'],
      subtotal: map['subtotal'] != null ? map['subtotal'].toDouble() : null,
      relacionPrecioIva: map['relacion_precio_iva'],
      alicuotaIva: map['alicuota_iva'] != null ? map['alicuota_iva'].toDouble() : null,
      iva: map['iva'] != null ? map['iva'].toDouble() : null,
      recargo: map['recargo'] != null ? map['recargo'].toDouble() : null,
      alicuotaDescuento: map['alicuota_descuento'] != null ? map['alicuota_descuento'].toDouble() : null,
      descuento: map['descuento'] != null ? map['descuento'].toDouble() : null,
      descuentoPromo: map['descuento_promo'] != null ? map['descuento_promo'].toDouble() : null,
      total: map['total'] != null ? map['total'].toDouble() : null,
      items: map['items'],
      cash: map['cash'] != null ? map['cash'].toDouble() : null,
      change: map['change'] != null ? map['change'].toDouble() : null,
      deuda: map['deuda'] != null ? map['deuda'].toDouble() : null,
      estadoPago: map['estado_pago'],
      status: map['status'],
      recordatorio: map['recordatorio'],
      canalVenta: map['canal_venta'],
      comercioId: map['comercio_id'],
      metodoPago: map['metodo_pago'],
      userId: map['user_id'],
      clienteId: map['cliente_id'],
      observaciones: map['observaciones'],
      fechaEntrega: map['fecha_entrega'] != null ? DateTime.parse(map['fecha_entrega']) : null,
      hojaRuta: map['hoja_ruta'],
      notaInterna: map['nota_interna'],
      caja: map['caja'],
      tipoComprobante: map['tipo_comprobante'],
      datosFacturacionId: map['datos_facturacion_id'],
    );
  }

  // Método para convertir una instancia de Sale a un mapa de datos
  Map<String, dynamic> toMap() {
    return {
      'nro_venta': nroVenta,
      'idVenta': idVenta,
      'subtotal': subtotal,
      'relacion_precio_iva': relacionPrecioIva,
      'alicuota_iva': alicuotaIva,
      'iva': iva,
      'recargo': recargo,
      'alicuota_descuento': alicuotaDescuento,
      'descuento': descuento,
      'descuento_promo': descuentoPromo,
      'total': total,
      'items': items,
      'cash': cash,
      'change': change,
      'deuda': deuda,
      'estado_pago': estadoPago,
      'status': status,
      'recordatorio': recordatorio,
      'canal_venta': canalVenta,
      'comercio_id': comercioId,
      'metodo_pago': metodoPago,
      'user_id': userId,
      'cliente_id': clienteId,
      'observaciones': observaciones,
      'fecha_entrega': fechaEntrega?.toIso8601String(),
      'hoja_ruta': hojaRuta,
      'nota_interna': notaInterna,
      'caja': caja,
      'tipo_comprobante': tipoComprobante,
      'datos_facturacion_id': datosFacturacionId,
    };
  }
}
