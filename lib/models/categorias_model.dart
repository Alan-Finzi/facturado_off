import 'dart:convert';
class CategoriaModel {
  final int? id;
  final String? name;



  CategoriaModel({
    this.id,
    this.name,
  });

  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    return CategoriaModel(
      id: json['id'] as int?,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}