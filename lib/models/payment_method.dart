import 'package:flutter/foundation.dart';

/// Modelo que representa un método de pago
///
/// Cada método de pago está asociado a un proveedor de pago
/// Ejemplos: 3 cuotas, transferencia bancaria, etc.
class PaymentMethod {
  /// ID único del método de pago
  final int id;

  /// ID del proveedor al que pertenece este método
  final int providerId;

  /// ID del comercio al que pertenece
  final int? comercioId;

  /// ID del creador del método de pago
  final int? creadorId;

  /// Nombre del método de pago (ej: "3 cuotas", "Transferencia")
  final String nombre;

  /// Categoría del método (1: Transferencia, 2: Débito, 3: Crédito, etc.)
  final int? categoria;

  /// ID de la cuenta asociada
  final int? cuenta;

  /// Porcentaje de recargo al usar este método
  final double recargo;

  /// Descripción adicional del método
  final String? descripcion;

  /// Indicador si se muestra en todas las sucursales
  final int? muestraSucursales;

  /// Indicador si tiene acreditación inmediata
  final int? acreditacionInmediata;

  /// Indicador si está eliminado (0=activo, 1=eliminado)
  final int? eliminado;

  /// Fecha de creación
  final String? createdAt;

  /// Fecha de última actualización
  final String? updatedAt;

  PaymentMethod({
    required this.id,
    required this.providerId,
    required this.nombre,
    required this.recargo,
    this.comercioId,
    this.creadorId,
    this.categoria,
    this.cuenta,
    this.descripcion,
    this.muestraSucursales,
    this.acreditacionInmediata,
    this.eliminado,
    this.createdAt,
    this.updatedAt,
  });

  /// Crea una instancia desde un mapa JSON
  factory PaymentMethod.fromJson(Map<String, dynamic> json, {int providerId = 0}) {
    return PaymentMethod(
      id: json['id'] ?? 0,
      providerId: providerId, // Usar el providerId pasado como parámetro
      nombre: json['nombre'] ?? '',
      recargo: _parseRecargo(json['recargo']),
      comercioId: json['comercio_id'],
      creadorId: json['creador_id'],
      categoria: json['categoria'],
      cuenta: json['cuenta'],
      descripcion: json['descripcion'],
      muestraSucursales: json['muestra_sucursales'],
      acreditacionInmediata: json['acreditacion_inmediata'],
      eliminado: json['eliminado'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  /// Parsea el valor de recargo a double, maneja diferentes tipos de entrada
  static double _parseRecargo(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) return value.toDouble();

    // Para el caso de strings, asegurarse de limpiar cualquier formato
    try {
      // Limpiar el string: reemplazar comas por puntos y eliminar espacios
      String cleanValue = value.toString().trim().replaceAll(',', '.');
      // Intentar parsear a double
      return double.tryParse(cleanValue) ?? 0.0;
    } catch (_) {
      print('Error al parsear recargo: $value');
      return 0.0;
    }
  }

  /// Convierte la instancia a un mapa para almacenar en la base de datos
  Map<String, dynamic> toMap() => {
    'id': id,
    'provider_id': providerId,
    'nombre': nombre,
    'recargo': recargo,
    'comercio_id': comercioId,
    'creador_id': creadorId,
    'categoria': categoria,
    'cuenta': cuenta,
    'descripcion': descripcion,
    'muestra_sucursales': muestraSucursales,
    'acreditacion_inmediata': acreditacionInmediata,
    'eliminado': eliminado,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  /// Crea una copia del método con algunos campos actualizados
  PaymentMethod copyWith({
    int? id,
    int? providerId,
    String? nombre,
    double? recargo,
    int? comercioId,
    int? creadorId,
    int? categoria,
    int? cuenta,
    String? descripcion,
    int? muestraSucursales,
    int? acreditacionInmediata,
    int? eliminado,
    String? createdAt,
    String? updatedAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      nombre: nombre ?? this.nombre,
      recargo: recargo ?? this.recargo,
      comercioId: comercioId ?? this.comercioId,
      creadorId: creadorId ?? this.creadorId,
      categoria: categoria ?? this.categoria,
      cuenta: cuenta ?? this.cuenta,
      descripcion: descripcion ?? this.descripcion,
      muestraSucursales: muestraSucursales ?? this.muestraSucursales,
      acreditacionInmediata: acreditacionInmediata ?? this.acreditacionInmediata,
      eliminado: eliminado ?? this.eliminado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PaymentMethod{id: $id, nombre: $nombre, recargo: $recargo%}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentMethod &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}