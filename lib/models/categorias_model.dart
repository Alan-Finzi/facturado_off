import 'dart:convert';

class CategoriaModel {
  final int id;
  final String comercioId;
  final String name;
  final int eliminado;
  final String createdAt;
  final String updatedAt;

  CategoriaModel({
    required this.id,
    required this.comercioId,
    required this.name,
    required this.eliminado,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    return CategoriaModel(
      id: json['id'],
      comercioId: json['comercio_id'],
      name: json['name'],
      eliminado: json['eliminado'] == true ? 1 : 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'comercio_id': comercioId,
      'name': name,
      'eliminado': eliminado,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
