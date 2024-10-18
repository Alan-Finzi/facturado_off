class ProductoConStockModel {
  final int? productId;
  final String? productName;
  final String? productType;
  final double? stock;
  final String? productBarcode;

  ProductoConStockModel({
     this.productId,
     this.productName,
     this.productType,
     this.stock,
     this.productBarcode,
  });

  // Método para crear una instancia de ProductoConStockModel desde un mapa
  factory ProductoConStockModel.fromMap(Map<String, dynamic> map) {
    return ProductoConStockModel(
      productId: map['id'],
      productName: map['productName']?.isNotEmpty == true ? map['productName'] : 'Sin info',
      productType: map['productType'],
      stock: map['stock'] is int ? (map['stock'] as int).toDouble() : map['stock']?.toDouble() ?? 0.0,
      productBarcode: map['productBarcode'],
    );
  }

  // Método para convertir la instancia a un mapa, si es necesario
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productType': productType,
      'stock': stock,
      'productBarcode': productBarcode,
    };
  }
}