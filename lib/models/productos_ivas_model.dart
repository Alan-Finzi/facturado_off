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
    int? _parseInt(dynamic v) =>
        v == null ? null : (v is int ? v : int.tryParse(v.toString()));
    return ProductosIvasModel(
      productId: _parseInt(map['product_id']),
      comercioId: _parseInt(map['comercio_id']),
      sucursalId: _parseInt(map['sucursal_id']),
      iva: map['iva'] != null ? double.tryParse(map['iva'].toString()) : null,
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