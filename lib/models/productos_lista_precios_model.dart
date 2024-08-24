class ProductosListaPreciosModel {
  final int? productId;
  final String? referenciaVariacion;
  final int? listaId;
  final double? precioLista;
  final int? comercioId;
  final int? eliminado;

  ProductosListaPreciosModel({
    this.productId,
    this.referenciaVariacion,
    this.listaId,
    this.precioLista,
    this.comercioId,
    this.eliminado,
  });

  factory ProductosListaPreciosModel.fromMap(Map<String, dynamic> map) {
    return ProductosListaPreciosModel(
      productId: map['product_id'],
      referenciaVariacion: map['referencia_variacion'],
      listaId: map['lista_id'],
      precioLista: map['precio_lista'],
      comercioId: map['comercio_id'],
      eliminado: map['eliminado'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'referencia_variacion': referenciaVariacion,
      'lista_id': listaId,
      'precio_lista': precioLista,
      'comercio_id': comercioId,
      'eliminado': eliminado,
    };
  }
}