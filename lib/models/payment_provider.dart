import 'package:flutter/foundation.dart';
import 'package:facturador_offline/models/payment_method.dart';

/// Modelo que representa un proveedor de método de pago
///
/// Ejemplos: Efectivo, Banco Santander, BBVA, etc.
/// Cada proveedor puede tener múltiples métodos de pago asociados
class PaymentProvider {
  /// ID único del proveedor
  final int id;

  /// Nombre del proveedor (ej: "Efectivo", "BBVA Francés")
  final String nombre;

  /// Nombre del creador del proveedor
  final String? creador;

  /// ID del creador del proveedor
  final int? creadorId;

  /// Tipo de proveedor (1: Efectivo, 2: Banco, 3: Tarjeta, etc.)
  final int? tipo;

  /// Indicador si se muestra en todas las sucursales
  final int? muestraSucursales;

  /// ID del comercio al que pertenece
  final int? comercioId;

  /// CBU asociado al proveedor (para bancos)
  final String? cbu;

  /// CUIT asociado al proveedor (para bancos)
  final String? cuit;

  /// Fecha de última actualización
  final String? updatedAt;

  /// Métodos de pago asociados a este proveedor
  final List<PaymentMethod>? metodosPago;

  PaymentProvider({
    required this.id,
    required this.nombre,
    this.creador,
    this.creadorId,
    this.tipo,
    this.muestraSucursales,
    this.comercioId,
    this.cbu,
    this.cuit,
    this.updatedAt,
    this.metodosPago,
  });

  /// Crea una instancia desde un mapa JSON
  factory PaymentProvider.fromJson(Map<String, dynamic> json) {
    // Procesa la lista de métodos de pago si existe
    List<PaymentMethod>? metodos;
    if (json['metodos_pago'] != null) {
      metodos = (json['metodos_pago'] as List)
          .map((metodo) => PaymentMethod.fromJson(metodo, providerId: json['id'] ?? 0))
          .toList();
    }

    return PaymentProvider(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      creador: json['creador'],
      creadorId: json['creador_id'],
      tipo: json['tipo'],
      muestraSucursales: json['muestra_sucursales'],
      comercioId: json['comercio_id'],
      cbu: json['cbu'],
      cuit: json['cuit'],
      updatedAt: json['updated_at'],
      metodosPago: metodos,
    );
  }

  /// Convierte la instancia a un mapa para almacenar en la base de datos
  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'creador': creador,
    'creador_id': creadorId,
    'tipo': tipo,
    'muestra_sucursales': muestraSucursales,
    'comercio_id': comercioId,
    'cbu': cbu,
    'cuit': cuit,
    'updated_at': updatedAt,
  };

  /// Crea una copia del proveedor con algunos campos actualizados
  PaymentProvider copyWith({
    int? id,
    String? nombre,
    String? creador,
    int? creadorId,
    int? tipo,
    int? muestraSucursales,
    int? comercioId,
    String? cbu,
    String? cuit,
    String? updatedAt,
    List<PaymentMethod>? metodosPago,
  }) {
    return PaymentProvider(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      creador: creador ?? this.creador,
      creadorId: creadorId ?? this.creadorId,
      tipo: tipo ?? this.tipo,
      muestraSucursales: muestraSucursales ?? this.muestraSucursales,
      comercioId: comercioId ?? this.comercioId,
      cbu: cbu ?? this.cbu,
      cuit: cuit ?? this.cuit,
      updatedAt: updatedAt ?? this.updatedAt,
      metodosPago: metodosPago ?? this.metodosPago,
    );
  }

  @override
  String toString() {
    return 'PaymentProvider{id: $id, nombre: $nombre}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentProvider &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}