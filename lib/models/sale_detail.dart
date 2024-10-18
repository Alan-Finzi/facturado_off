class SaleDetails {
  final int? productId;
  final String? referenciaVariacion;
  final String? productName;
  final String? productBarcode;
  final double? cost;
  final double? price;
  final double? precioOriginal;
  final double? recargo;
  final double? descuento;
  final double? alicuotaIva; // En desuso
  final double? ivaTotal;
  final double? iva;
  final int? quantity;
  final int? relacionPrecioIva;
  final int? saleId;
  final String? canalVenta;
  final int? comercioId;
  final int? metodoPago;
  final int? userId;
  final int? clienteId;
  final int? seccionalmacenId;
  final String? estado;
  final String? comentario;
  final bool? eliminado; // Puede ser 1 o 0
  final int? caja;
  final int? stockDeSucursalId; // En desuso
  final int? idPromo;
  final String? nombrePromo;
  final double? descuentoPromo;
  final int? cantidadPromo;

  SaleDetails({
    this.productId,
    this.referenciaVariacion,
    this.productName,
    this.productBarcode,
    this.cost,
    this.price,
    this.precioOriginal,
    this.recargo,
    this.descuento,
    this.alicuotaIva,
    this.ivaTotal,
    this.iva,
    this.quantity,
    this.relacionPrecioIva,
    this.saleId,
    this.canalVenta,
    this.comercioId,
    this.metodoPago,
    this.userId,
    this.clienteId,
    this.seccionalmacenId,
    this.estado,
    this.comentario,
    this.eliminado,
    this.caja,
    this.stockDeSucursalId,
    this.idPromo,
    this.nombrePromo,
    this.descuentoPromo,
    this.cantidadPromo,
  });

  // Método para crear una instancia de SaleDetails desde un mapa de datos (por ejemplo, JSON o SQLite)
  factory SaleDetails.fromMap(Map<String, dynamic> map) {
    return SaleDetails(
      productId: map['product_id'],
      referenciaVariacion: map['referencia_variacion'],
      productName: map['product_name'],
      productBarcode: map['product_barcode'],
      cost: map['cost'] != null ? map['cost'].toDouble() : null,
      price: map['price'] != null ? map['price'].toDouble() : null,
      precioOriginal: map['precio_original'] != null ? map['precio_original'].toDouble() : null,
      recargo: map['recargo'] != null ? map['recargo'].toDouble() : null,
      descuento: map['descuento'] != null ? map['descuento'].toDouble() : null,
      alicuotaIva: map['alicuota_iva'] != null ? map['alicuota_iva'].toDouble() : null,
      ivaTotal: map['iva_total'] != null ? map['iva_total'].toDouble() : null,
      iva: map['iva'] != null ? map['iva'].toDouble() : null,
      quantity: map['quantity'],
      relacionPrecioIva: map['relacion_precio_iva'],
      saleId: map['sale_id'],
      canalVenta: map['canal_venta'],
      comercioId: map['comercio_id'],
      metodoPago: map['metodo_pago'],
      userId: map['user_id'],
      clienteId: map['cliente_id'],
      seccionalmacenId: map['seccionalmacen_id'],
      estado: map['estado'],
      comentario: map['comentario'],
      eliminado: map['eliminado'] == 1,
      caja: map['caja'],
      stockDeSucursalId: map['stock_de_sucursal_id'],
      idPromo: map['id_promo'],
      nombrePromo: map['nombre_promo'],
      descuentoPromo: map['descuento_promo'] != null ? map['descuento_promo'].toDouble() : null,
      cantidadPromo: map['cantidad_promo'],
    );
  }

  // Método para convertir una instancia de SaleDetails a un mapa de datos
  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'referencia_variacion': referenciaVariacion,
      'product_name': productName,
      'product_barcode': productBarcode,
      'cost': cost,
      'price': price,
      'precio_original': precioOriginal,
      'recargo': recargo,
      'descuento': descuento,
      'alicuota_iva': alicuotaIva,
      'iva_total': ivaTotal,
      'iva': iva,
      'quantity': quantity,
      'relacion_precio_iva': relacionPrecioIva,
      'sale_id': saleId,
      'canal_venta': canalVenta,
      'comercio_id': comercioId,
      'metodo_pago': metodoPago,
      'user_id': userId,
      'cliente_id': clienteId,
      'seccionalmacen_id': seccionalmacenId,
      'estado': estado,
      'comentario': comentario,
      'eliminado': eliminado == true ? 1 : 0,
      'caja': caja,
      'stock_de_sucursal_id': stockDeSucursalId,
      'id_promo': idPromo,
      'nombre_promo': nombrePromo,
      'descuento_promo': descuentoPromo,
      'cantidad_promo': cantidadPromo,
    };
  }
}
