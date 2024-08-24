class ListaPreciosModel {
  final int? id; // Agregado el campo id
  final String? nombre;
  final int? comercioId;
  final String? descripcion;
  final int? eliminado;
  final String? wcKey;

  ListaPreciosModel({
    this.id, // Inicializado en el constructor
    this.nombre,
    this.comercioId,
    this.descripcion,
    this.eliminado,
    this.wcKey,
  });

  factory ListaPreciosModel.fromMap(Map<String, dynamic> map) {
    return ListaPreciosModel(
      id: map['id'], // Mapear el id desde el mapa
      nombre: map['nombre'],
      comercioId: map['comercio_id'],
      descripcion: map['descripcion'],
      eliminado: map['eliminado'],
      wcKey: map['wc_key'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'comercio_id': comercioId,
      'descripcion': descripcion,
      'eliminado': eliminado,
      'wc_key': wcKey,
    };
  }
}
