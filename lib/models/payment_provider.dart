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
      try {
        metodos = (json['metodos_pago'] as List)
            .map((metodo) => PaymentMethod.fromJson(metodo, providerId: json['id'] ?? 0))
            .toList();
      } catch (e) {
        print('Error al procesar metodos_pago: $e para provider ID: ${json['id']}');
        metodos = []; // Evitar que sea null
      }
    } else {
      metodos = []; // Inicializar con lista vacía en lugar de null
    }

    // Asegurarse de que el ID sea un entero
    int id;
    try {
      if (json['id'] is int) {
        id = json['id'];
      } else if (json['id'] is String) {
        id = int.tryParse(json['id']) ?? 0;
      } else {
        id = 0;
      }
    } catch (_) {
      id = 0;
      print('Error al parsear ID de provider: ${json['id']}');
    }

    // Parsear creador_id como entero
    int? creadorId;
    if (json['creador_id'] != null) {
      try {
        if (json['creador_id'] is int) {
          creadorId = json['creador_id'];
        } else if (json['creador_id'] is String) {
          creadorId = int.tryParse(json['creador_id']);
        }
      } catch (e) {
        print('Error al parsear creador_id: ${json['creador_id']}');
      }
    }

    // Parsear comercio_id como entero
    int? comercioId;
    if (json['comercio_id'] != null) {
      try {
        if (json['comercio_id'] is int) {
          comercioId = json['comercio_id'];
        } else if (json['comercio_id'] is String) {
          comercioId = int.tryParse(json['comercio_id']);
        }
      } catch (e) {
        print('Error al parsear comercio_id: ${json['comercio_id']}');
      }
    }

    return PaymentProvider(
      id: id,
      nombre: json['nombre'] ?? '',
      creador: json['creador']?.toString(),
      creadorId: creadorId,
      tipo: json['tipo'] is int ? json['tipo'] : (int.tryParse(json['tipo']?.toString() ?? '') ?? null),
      muestraSucursales: json['muestra_sucursales'] is int ? json['muestra_sucursales'] : (int.tryParse(json['muestra_sucursales']?.toString() ?? '') ?? null),
      comercioId: comercioId,
      cbu: json['cbu']?.toString(),
      cuit: json['cuit']?.toString(),
      updatedAt: json['updated_at']?.toString(),
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