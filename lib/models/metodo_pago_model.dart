import 'dart:convert';

class MetodoPagoModel {
  final int? id;
  final String? nombre;
  final int? comercioId;
  final double? porcentajeRecargo;
  final int? acreditacionInmediata;
  final String? descripcion;
  final int? eliminado;
  final String? createdAt;
  final String? updatedAt;
  // Nuevos campos para guardar información de la entidad/banco
  final String? entidadNombre;
  final int? entidadId;

  MetodoPagoModel({
    this.id,
    this.nombre,
    this.comercioId,
    this.porcentajeRecargo,
    this.acreditacionInmediata,
    this.descripcion,
    this.eliminado,
    this.createdAt,
    this.updatedAt,
    this.entidadNombre,
    this.entidadId,
  });

  // Constructor desde JSON
  factory MetodoPagoModel.fromJson(Map<String, dynamic> json) {
    return MetodoPagoModel(
      id: json['id'],
      nombre: json['nombre'],
      comercioId: json['comercio_id'],
      porcentajeRecargo: json['porcentaje_recargo'] != null
          ? double.tryParse(json['porcentaje_recargo'].toString())
          : null,
      acreditacionInmediata: json['acreditacion_inmediata'],
      descripcion: json['descripcion'],
      eliminado: json['eliminado'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      entidadNombre: json['entidad_nombre'],
      entidadId: json['entidad_id'],
    );
  }

  // Convertir a Map para almacenar en BD
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'comercio_id': comercioId,
      'porcentaje_recargo': porcentajeRecargo,
      'acreditacion_inmediata': acreditacionInmediata,
      'descripcion': descripcion,
      'eliminado': eliminado,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'entidad_nombre': entidadNombre,
      'entidad_id': entidadId,
    };
  }

  // Para debugging
  @override
  String toString() {
    return 'MetodoPagoModel{id: $id, nombre: $nombre, comercioId: $comercioId, porcentajeRecargo: $porcentajeRecargo, acreditacionInmediata: $acreditacionInmediata, entidadNombre: $entidadNombre}';
  }

  // Convertir lista de métodos de pago desde JSON
  static List<MetodoPagoModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => MetodoPagoModel.fromJson(json)).toList();
  }
}