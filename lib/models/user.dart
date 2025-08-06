class User {
  static User? currencyUser; // Propiedad estática para almacenar el usuario actual
  final int? id;
  final String? username;
  final String? password;
  final String? nombreUsuario;
  final String? apellidoUsuario;
  final int? cantidadSucursales;
  final int? cantidadEmpleados;
  final String? name;
  final int? sucursal;
  final String? profile;
  final String? status;
   String? email;
  final String? externalAuth;
  final String? externalId;
  final DateTime? emailVerifiedAt;
  final DateTime? confirmedAt;
  final int? plan;
  final DateTime? lastLogin;
  final int? cantidadLogin;
  final String? comercioId;
  final int? clienteId;
  final String? image;
  final int? casaCentralUserId;
  final int? idListaPrecio;

  User({
    required this.username,
    required this.password,
    this.id,
    this.idListaPrecio,
    this.nombreUsuario,
    this.apellidoUsuario,
    this.cantidadSucursales,
     this.cantidadEmpleados,
     this.name,
     this.sucursal,
     this.email,
     this.profile,
     this.status,
    this.externalAuth,
    this.externalId,
    this.emailVerifiedAt,
    this.confirmedAt,
     this.plan,
    this.lastLogin,
     this.cantidadLogin,
     this.comercioId,
    this.clienteId,
    this.image,
    this.casaCentralUserId,
  });

  // Método para actualizar el currencyUser
  static void setCurrencyUser(User user) {
    currencyUser = user;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      id: json['id'],
      password: json['password'],
      nombreUsuario: json['nombre_usuario'],
      apellidoUsuario: json['apellido_usuario'],
      name: json['name'],
      idListaPrecio:json['lista_defecto'],
      sucursal: json['sucursal'],
      email: json['email'],
      profile: json['profile'],
      status: json['status'],
      externalAuth: json['external_auth'],
      externalId: json['external_id'],
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'])
          : null,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'])
          : null,
      plan: json['plan'],
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
      cantidadLogin: json['cantidad_login'],
      comercioId: json['comercio_id'] is int
          ? json['comercio_id'].toString() // Convertir a String si es un int
          : json['comercio_id'] as String?,
      clienteId: json['cliente_id'],
      image: json['image'],
      casaCentralUserId: json['casa_central_user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':id,
      'username': username,
      'password': password,
      'nombre_usuario': nombreUsuario,
      'apellido_usuario': apellidoUsuario,
      'cantidad_sucursales': cantidadSucursales,
      'cantidad_empleados': cantidadEmpleados,
      'name': name,
      'sucursal': sucursal,
      'email': email,
      'profile': profile,
      'status': status,
      'id_lista_precio':idListaPrecio,
      'external_auth': externalAuth,
      'external_id': externalId,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'confirmed_at': confirmedAt?.toIso8601String(),
      'plan': plan,
      'last_login': lastLogin?.toIso8601String(),
      'cantidad_login': cantidadLogin,
      'comercio_id': comercioId,
      'cliente_id': clienteId,
      'image': image,
      'casa_central_user_id': casaCentralUserId,
    };
  }
}
