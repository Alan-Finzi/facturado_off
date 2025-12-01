import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Modelo que representa un detalle de venta (un producto vendido)
class SaleDetail extends Equatable {
  /// ID único del detalle (autogenerado por SQLite)
  final int? id;

  /// ID de la venta a la que pertenece este detalle
  final int ventaId;

  /// ID del producto vendido
  final int productoId;

  /// Código del producto (barcode o código interno)
  final String? codigoProducto;

  /// Nombre del producto como estaba al momento de la venta
  final String nombreProducto;

  /// Descripción adicional del producto
  final String? descripcion;

  /// Cantidad vendida
  final double cantidad;

  /// Unidad de medida del producto
  final String? unidadMedida;

  /// Precio unitario sin impuestos
  final double precioUnitario;

  /// Porcentaje de IVA aplicado
  final double porcentajeIva;

  /// Monto de IVA para este producto
  final double montoIva;

  /// Precio final unitario (con IVA)
  final double precioFinal;

  /// Subtotal sin impuestos (precioUnitario * cantidad)
  final double subtotal;

  /// Total con impuestos (precioFinal * cantidad)
  final double total;

  /// Porcentaje de descuento aplicado a este producto
  final double descuento;

  /// Monto del descuento aplicado
  final double montoDescuento;

  /// Nota interna sobre este producto
  final String? notaInterna;

  /// Observaciones visibles para el cliente
  final String? observaciones;

  /// Estado de sincronización (0=no sincronizado, 1=sincronizado)
  final int sincronizado;

  /// Estado de borrado lógico (0=activo, 1=eliminado)
  final int eliminado;

  /// ID de la categoría del producto
  final int? categoriaId;

  /// Nombre de la categoría del producto
  final String? categoriaNombre;

  /// Fecha y hora de creación del registro
  final DateTime createdAt;

  /// Fecha y hora de última actualización del registro
  final DateTime updatedAt;

  /// Constructor principal
  SaleDetail({
    this.id,
    required this.ventaId,
    required this.productoId,
    this.codigoProducto,
    required this.nombreProducto,
    this.descripcion,
    required this.cantidad,
    this.unidadMedida,
    required this.precioUnitario,
    required this.porcentajeIva,
    required this.montoIva,
    required this.precioFinal,
    required this.subtotal,
    required this.total,
    this.descuento = 0.0,
    this.montoDescuento = 0.0,
    this.notaInterna,
    this.observaciones,
    this.sincronizado = 0,
    this.eliminado = 0,
    this.categoriaId,
    this.categoriaNombre,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Crear una copia del detalle con algunos campos modificados
  SaleDetail copyWith({
    int? id,
    int? ventaId,
    int? productoId,
    String? codigoProducto,
    String? nombreProducto,
    String? descripcion,
    double? cantidad,
    String? unidadMedida,
    double? precioUnitario,
    double? porcentajeIva,
    double? montoIva,
    double? precioFinal,
    double? subtotal,
    double? total,
    double? descuento,
    double? montoDescuento,
    String? notaInterna,
    String? observaciones,
    int? sincronizado,
    int? eliminado,
    int? categoriaId,
    String? categoriaNombre,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SaleDetail(
      id: id ?? this.id,
      ventaId: ventaId ?? this.ventaId,
      productoId: productoId ?? this.productoId,
      codigoProducto: codigoProducto ?? this.codigoProducto,
      nombreProducto: nombreProducto ?? this.nombreProducto,
      descripcion: descripcion ?? this.descripcion,
      cantidad: cantidad ?? this.cantidad,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      porcentajeIva: porcentajeIva ?? this.porcentajeIva,
      montoIva: montoIva ?? this.montoIva,
      precioFinal: precioFinal ?? this.precioFinal,
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
      descuento: descuento ?? this.descuento,
      montoDescuento: montoDescuento ?? this.montoDescuento,
      notaInterna: notaInterna ?? this.notaInterna,
      observaciones: observaciones ?? this.observaciones,
      sincronizado: sincronizado ?? this.sincronizado,
      eliminado: eliminado ?? this.eliminado,
      categoriaId: categoriaId ?? this.categoriaId,
      categoriaNombre: categoriaNombre ?? this.categoriaNombre,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Factory constructor para crear un detalle de venta a partir de un mapa
  factory SaleDetail.fromMap(Map<String, dynamic> map) {
    return SaleDetail(
      id: map['id'],
      ventaId: map['venta_id'],
      productoId: map['producto_id'],
      codigoProducto: map['codigo_producto'],
      nombreProducto: map['nombre_producto'] ?? '',
      descripcion: map['descripcion'],
      cantidad: map['cantidad']?.toDouble() ?? 0.0,
      unidadMedida: map['unidad_medida'],
      precioUnitario: map['precio_unitario']?.toDouble() ?? 0.0,
      porcentajeIva: map['porcentaje_iva']?.toDouble() ?? 0.0,
      montoIva: map['monto_iva']?.toDouble() ?? 0.0,
      precioFinal: map['precio_final']?.toDouble() ?? 0.0,
      subtotal: map['subtotal']?.toDouble() ?? 0.0,
      total: map['total']?.toDouble() ?? 0.0,
      descuento: map['descuento']?.toDouble() ?? 0.0,
      montoDescuento: map['monto_descuento']?.toDouble() ?? 0.0,
      notaInterna: map['nota_interna'],
      observaciones: map['observaciones'],
      sincronizado: map['sincronizado'] ?? 0,
      eliminado: map['eliminado'] ?? 0,
      categoriaId: map['categoria_id'],
      categoriaNombre: map['categoria_nombre'],
      createdAt: map['created_at'] is DateTime
          ? map['created_at']
          : DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updated_at'] is DateTime
          ? map['updated_at']
          : DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Factory constructor para crear un detalle de venta desde un JSON
  factory SaleDetail.fromJson(String source) => SaleDetail.fromMap(json.decode(source));

  /// Convertir el detalle de venta a un mapa para almacenar en la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'venta_id': ventaId,
      'producto_id': productoId,
      'codigo_producto': codigoProducto,
      'nombre_producto': nombreProducto,
      'descripcion': descripcion,
      'cantidad': cantidad,
      'unidad_medida': unidadMedida,
      'precio_unitario': precioUnitario,
      'porcentaje_iva': porcentajeIva,
      'monto_iva': montoIva,
      'precio_final': precioFinal,
      'subtotal': subtotal,
      'total': total,
      'descuento': descuento,
      'monto_descuento': montoDescuento,
      'nota_interna': notaInterna,
      'observaciones': observaciones,
      'sincronizado': sincronizado,
      'eliminado': eliminado,
      'categoria_id': categoriaId,
      'categoria_nombre': categoriaNombre,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convertir el detalle de venta a JSON para serialización
  String toJson() => json.encode(toMap());

  /// Para igualdad y comparación de objetos
  @override
  List<Object?> get props => [
        id,
        ventaId,
        productoId,
        codigoProducto,
        nombreProducto,
        descripcion,
        cantidad,
        unidadMedida,
        precioUnitario,
        porcentajeIva,
        montoIva,
        precioFinal,
        subtotal,
        total,
        descuento,
        montoDescuento,
        notaInterna,
        observaciones,
        sincronizado,
        eliminado,
        categoriaId,
        categoriaNombre,
        createdAt,
        updatedAt,
      ];

  /// Representación de string para depuración
  @override
  String toString() {
    return 'SaleDetail(id: $id, ventaId: $ventaId, productoId: $productoId, nombreProducto: $nombreProducto, cantidad: $cantidad, total: $total)';
  }

  /// Método auxiliar para calcular totales a partir del precio unitario, cantidad, IVA y descuento
  factory SaleDetail.calculate({
    int? id,
    required int ventaId,
    required int productoId,
    String? codigoProducto,
    required String nombreProducto,
    String? descripcion,
    required double cantidad,
    String? unidadMedida,
    required double precioUnitario,
    required double porcentajeIva,
    double descuento = 0.0,
    String? notaInterna,
    String? observaciones,
    int? categoriaId,
    String? categoriaNombre,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    // Calcular montoIva, subtotal, montoDescuento y total
    final double subtotalSinDescuento = precioUnitario * cantidad;
    final double montoDescuento = (descuento / 100) * subtotalSinDescuento;
    final double subtotal = subtotalSinDescuento - montoDescuento;
    final double montoIva = subtotal * (porcentajeIva / 100);
    final double precioFinal = precioUnitario * (1 + porcentajeIva / 100);
    final double total = subtotal + montoIva;

    return SaleDetail(
      id: id,
      ventaId: ventaId,
      productoId: productoId,
      codigoProducto: codigoProducto,
      nombreProducto: nombreProducto,
      descripcion: descripcion,
      cantidad: cantidad,
      unidadMedida: unidadMedida,
      precioUnitario: precioUnitario,
      porcentajeIva: porcentajeIva,
      montoIva: montoIva,
      precioFinal: precioFinal,
      subtotal: subtotal,
      total: total,
      descuento: descuento,
      montoDescuento: montoDescuento,
      notaInterna: notaInterna,
      observaciones: observaciones,
      categoriaId: categoriaId,
      categoriaNombre: categoriaNombre,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}