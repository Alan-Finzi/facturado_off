class ProductosIvasModel {
  final int? productId;
  final int? comercioId;
  final int? sucursalId;
  final double? iva;

  ProductosIvasModel({
    this.productId,
    this.comercioId,
    this.sucursalId,
    this.iva,
  });

  factory ProductosIvasModel.fromMap(Map<String, dynamic> map) {
    return ProductosIvasModel(
      productId: map['product_id'],
      comercioId: map['comercio_id'],
      sucursalId: map['sucursal_id'],
      iva: map['iva'] != null ? (map['iva'] is int ? map['iva'].toDouble() : map['iva']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'comercio_id': comercioId,
      'sucursal_id': sucursalId,
      'iva': iva,
    };
  }
}