class ProductosStockSucursalesModel {
  final int? productId;
  final String? referenciaVariacion;
  final int? comercioId;
  final int? sucursalId;
  final int? almacenId;
  final int? stock;
  final int? stockReal;
  final int? eliminado;

  ProductosStockSucursalesModel({
    this.productId,
    this.referenciaVariacion,
    this.comercioId,
    this.sucursalId,
    this.almacenId,
    this.stock,
    this.stockReal,
    this.eliminado,
  });

  factory ProductosStockSucursalesModel.fromMap(Map<String, dynamic> map) {
    return ProductosStockSucursalesModel(
      productId: map['product_id'],
      referenciaVariacion: map['referencia_variacion'],
      comercioId: map['comercio_id'],
      sucursalId: map['sucursal_id'],
      almacenId: map['almacen_id'],
      stock: map['stock'],
      stockReal: map['stock_real'],
      eliminado: map['eliminado'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'referencia_variacion': referenciaVariacion,
      'comercio_id': comercioId,
      'sucursal_id': sucursalId,
      'almacen_id': almacenId,
      'stock': stock,
      'stock_real': stockReal,
      'eliminado': eliminado,
    };
  }
}