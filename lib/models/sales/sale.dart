import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'sale_detail.dart';

/// Modelo que representa una venta completa
class Sale extends Equatable {
  /// ID único de la venta (autogenerado por SQLite)
  final int? id;

  /// Número de venta, puede ser un número secuencial o un código personalizado
  final String? nroVenta;

  /// ID alternativo para la venta, útil para sincronización con servicios externos
  final String? idVenta;

  /// Fecha y hora de la venta
  final DateTime fecha;

  /// ID del comercio asociado a la venta
  final int comercioId;

  /// ID del cliente asociado a la venta (null si es venta sin cliente)
  final int? clienteId;

  /// Domicilio de entrega (si es diferente al del cliente)
  final String? domicilioEntrega;

  /// Tipo de comprobante fiscal (factura A, B, ticket, etc.)
  final String? tipoComprobante;

  /// ID de los datos de facturación utilizados
  final int? datosFacturacionId;

  /// Subtotal de la venta sin impuestos
  final double subtotal;

  /// Total de IVA
  final double iva;

  /// Total final de la venta
  final double total;

  /// Descuento aplicado a la venta completa
  final double descuento;

  /// Recargo aplicado a la venta completa
  final double recargo;

  /// Método de pago utilizado (puede ser serializado como JSON para pagos múltiples)
  final String metodoPago;

  /// Detalles adicionales del método de pago (para pagos divididos)
  final String? metodoPagoDetalles;

  /// Estado de sincronización (0=no sincronizado, 1=sincronizado)
  final int sincronizado;

  /// Estado de borrado lógico (0=activo, 1=eliminado)
  final int eliminado;

  /// Estado de la venta (pendiente, completada, cancelada, etc.)
  final String estado;

  /// ID del usuario que realizó la venta
  final int? userId;

  /// Canal de venta (mostrador, online, telefónica, etc.)
  final String? canalVenta;

  /// ID de la caja donde se registró la venta
  final int? cajaId;

  /// Nota interna sobre la venta (visible solo para el comercio)
  final String? notaInterna;

  /// Observaciones generales (pueden ser visibles para el cliente)
  final String? observaciones;

  /// Fecha y hora de creación del registro
  final DateTime createdAt;

  /// Fecha y hora de última actualización del registro
  final DateTime updatedAt;

  /// Detalles de la venta (productos)
  final List<SaleDetail>? detalles;

  /// Constructor principal
  Sale({
    this.id,
    this.nroVenta,
    this.idVenta,
    required this.fecha,
    required this.comercioId,
    this.clienteId,
    this.domicilioEntrega,
    this.tipoComprobante,
    this.datosFacturacionId,
    required this.subtotal,
    required this.iva,
    required this.total,
    this.descuento = 0.0,
    this.recargo = 0.0,
    required this.metodoPago,
    this.metodoPagoDetalles,
    this.sincronizado = 0,
    this.eliminado = 0,
    required this.estado,
    this.userId,
    this.canalVenta,
    this.cajaId,
    this.notaInterna,
    this.observaciones,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.detalles,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Crear una copia de la venta con algunos campos modificados
  Sale copyWith({
    int? id,
    String? nroVenta,
    String? idVenta,
    DateTime? fecha,
    int? comercioId,
    int? clienteId,
    String? domicilioEntrega,
    String? tipoComprobante,
    int? datosFacturacionId,
    double? subtotal,
    double? iva,
    double? total,
    double? descuento,
    double? recargo,
    String? metodoPago,
    String? metodoPagoDetalles,
    int? sincronizado,
    int? eliminado,
    String? estado,
    int? userId,
    String? canalVenta,
    int? cajaId,
    String? notaInterna,
    String? observaciones,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SaleDetail>? detalles,
  }) {
    return Sale(
      id: id ?? this.id,
      nroVenta: nroVenta ?? this.nroVenta,
      idVenta: idVenta ?? this.idVenta,
      fecha: fecha ?? this.fecha,
      comercioId: comercioId ?? this.comercioId,
      clienteId: clienteId ?? this.clienteId,
      domicilioEntrega: domicilioEntrega ?? this.domicilioEntrega,
      tipoComprobante: tipoComprobante ?? this.tipoComprobante,
      datosFacturacionId: datosFacturacionId ?? this.datosFacturacionId,
      subtotal: subtotal ?? this.subtotal,
      iva: iva ?? this.iva,
      total: total ?? this.total,
      descuento: descuento ?? this.descuento,
      recargo: recargo ?? this.recargo,
      metodoPago: metodoPago ?? this.metodoPago,
      metodoPagoDetalles: metodoPagoDetalles ?? this.metodoPagoDetalles,
      sincronizado: sincronizado ?? this.sincronizado,
      eliminado: eliminado ?? this.eliminado,
      estado: estado ?? this.estado,
      userId: userId ?? this.userId,
      canalVenta: canalVenta ?? this.canalVenta,
      cajaId: cajaId ?? this.cajaId,
      notaInterna: notaInterna ?? this.notaInterna,
      observaciones: observaciones ?? this.observaciones,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      detalles: detalles ?? this.detalles,
    );
  }

  /// Factory constructor para crear una venta a partir de un mapa
  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      nroVenta: map['nro_venta'],
      idVenta: map['id_venta'],
      fecha: map['fecha'] is DateTime
          ? map['fecha']
          : DateTime.parse(map['fecha'] ?? DateTime.now().toIso8601String()),
      comercioId: map['comercio_id'],
      clienteId: map['cliente_id'],
      domicilioEntrega: map['domicilio_entrega'],
      tipoComprobante: map['tipo_comprobante'],
      datosFacturacionId: map['datos_facturacion_id'],
      subtotal: map['subtotal']?.toDouble() ?? 0.0,
      iva: map['iva']?.toDouble() ?? 0.0,
      total: map['total']?.toDouble() ?? 0.0,
      descuento: map['descuento']?.toDouble() ?? 0.0,
      recargo: map['recargo']?.toDouble() ?? 0.0,
      metodoPago: map['metodo_pago'] ?? '',
      metodoPagoDetalles: map['metodo_pago_detalles'],
      sincronizado: map['sincronizado'] ?? 0,
      eliminado: map['eliminado'] ?? 0,
      estado: map['estado'] ?? 'pendiente',
      userId: map['user_id'],
      canalVenta: map['canal_venta'],
      cajaId: map['caja_id'],
      notaInterna: map['nota_interna'],
      observaciones: map['observaciones'],
      createdAt: map['created_at'] is DateTime
          ? map['created_at']
          : DateTime.parse(
              map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updated_at'] is DateTime
          ? map['updated_at']
          : DateTime.parse(
              map['updated_at'] ?? DateTime.now().toIso8601String()),
      detalles: map['detalles'] != null
          ? List<SaleDetail>.from(
              (map['detalles'] as List).map((x) => SaleDetail.fromMap(x)))
          : null,
    );
  }

  /// Factory constructor para crear una venta desde un JSON
  factory Sale.fromJson(String source) => Sale.fromMap(json.decode(source));

  /// Convertir la venta a un mapa para almacenar en la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nro_venta': nroVenta,
      'id_venta': idVenta,
      'fecha': fecha.toIso8601String(),
      'comercio_id': comercioId,
      'cliente_id': clienteId,
      'domicilio_entrega': domicilioEntrega,
      'tipo_comprobante': tipoComprobante,
      'datos_facturacion_id': datosFacturacionId,
      'subtotal': subtotal,
      'iva': iva,
      'total': total,
      'descuento': descuento,
      'recargo': recargo,
      'metodo_pago': metodoPago,
      'metodo_pago_detalles': metodoPagoDetalles,
      'sincronizado': sincronizado,
      'eliminado': eliminado,
      'estado': estado,
      'user_id': userId,
      'canal_venta': canalVenta,
      'caja_id': cajaId,
      'nota_interna': notaInterna,
      'observaciones': observaciones,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convertir la venta a JSON para serialización
  String toJson() => json.encode(toMap());

  /// Para igualdad y comparación de objetos
  @override
  List<Object?> get props => [
        id,
        nroVenta,
        idVenta,
        fecha,
        comercioId,
        clienteId,
        domicilioEntrega,
        tipoComprobante,
        datosFacturacionId,
        subtotal,
        iva,
        total,
        descuento,
        recargo,
        metodoPago,
        metodoPagoDetalles,
        sincronizado,
        eliminado,
        estado,
        userId,
        canalVenta,
        cajaId,
        notaInterna,
        observaciones,
        createdAt,
        updatedAt,
      ];

  /// Representación de string para depuración
  @override
  String toString() {
    return 'Sale(id: $id, nroVenta: $nroVenta, fecha: $fecha, total: $total, estado: $estado)';
  }
}