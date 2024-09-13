class ClientesMostrador {
  static ClientesMostrador currentCompany = ClientesMostrador();
  final int? creadorId;
  final String? idCliente;
  final String? nombre;
  final int? sucursalId;
  final int? listaPrecio;
  final int? comercioId;
  final DateTime? lastSale;
  final DateTime? recontacto;
  final int? plazoCuentaCorriente;
  final double? montoMaximoCuentaCorriente;
  final double? saldoInicialCuentaCorriente;
  final DateTime? fechaInicialCuentaCorriente;
  final String? pais;
  final String? codigoPostal;
  final String? depto;
  final String? piso;
  final String? altura;
  final int? eliminado;
  final String? email;
  final String? telefono;
  final String? observaciones;
  final String? localidad;
  final String? barrio;
  final String? provincia;
  final String? direccion;
  final String? dni;
  final String? status;
  final String? image;
  final String? wcCustomerId;
  final int? activo;  // Campo añadido para el estado del cliente

  ClientesMostrador({
    this.creadorId,
    this.idCliente,
    this.nombre,
    this.sucursalId,
    this.listaPrecio,
    this.comercioId,
    this.lastSale,
    this.recontacto,
    this.plazoCuentaCorriente,
    this.montoMaximoCuentaCorriente,
    this.saldoInicialCuentaCorriente,
    this.fechaInicialCuentaCorriente,
    this.pais,
    this.codigoPostal,
    this.depto,
    this.piso,
    this.altura,
    this.eliminado,
    this.email,
    this.telefono,
    this.observaciones,
    this.localidad,
    this.barrio,
    this.provincia,
    this.direccion,
    this.dni,
    this.status,
    this.image,
    this.wcCustomerId,
    this.activo = 1, // Valor por defecto para indicar que el cliente está activo
  });

  factory ClientesMostrador.fromJson(Map<String, dynamic> json) {
    return ClientesMostrador(
      creadorId: json['creador_id'],
      idCliente: json['id_cliente'],
      nombre: json['nombre'],
      sucursalId: json['sucursal_id'],
      listaPrecio: json['lista_precio'],
      comercioId: json['comercio_id'],
      lastSale: json['last_sale'] != null ? DateTime.parse(json['last_sale']) : null,
      recontacto: json['recontacto'] != null ? DateTime.parse(json['recontacto']) : null,
      plazoCuentaCorriente: json['plazo_cuenta_corriente'],
      montoMaximoCuentaCorriente: json['monto_maximo_cuenta_corriente'].toDouble(),
      saldoInicialCuentaCorriente: json['saldo_inicial_cuenta_corriente'].toDouble(),
      fechaInicialCuentaCorriente: json['fecha_inicial_cuenta_corriente'] != null ? DateTime.parse(json['fecha_inicial_cuenta_corriente']) : null,
      pais: json['pais'],
      codigoPostal: json['codigo_postal'],
      depto: json['depto'],
      piso: json['piso'],
      altura: json['altura'],
      eliminado: json['eliminado'],
      email: json['email'],
      telefono: json['telefono'],
      observaciones: json['observaciones'],
      localidad: json['localidad'],
      barrio: json['barrio'],
      provincia: json['provincia'],
      direccion: json['direccion'],
      dni: json['dni'],
      status: json['status'],
      image: json['image'],
      wcCustomerId: json['wc_customer_id'],
      activo: json['activo'] ?? 1, // Valor por defecto para clientes nuevos
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'creador_id': creadorId,
      'id_cliente': idCliente,
      'nombre': nombre,
      'sucursal_id': sucursalId,
      'lista_precio': listaPrecio,
      'comercio_id': comercioId,
      'last_sale': lastSale?.toIso8601String(),
      'recontacto': recontacto?.toIso8601String(),
      'plazo_cuenta_corriente': plazoCuentaCorriente,
      'monto_maximo_cuenta_corriente': montoMaximoCuentaCorriente,
      'saldo_inicial_cuenta_corriente': saldoInicialCuentaCorriente,
      'fecha_inicial_cuenta_corriente': fechaInicialCuentaCorriente?.toIso8601String(),
      'pais': pais,
      'codigo_postal': codigoPostal,
      'depto': depto,
      'piso': piso,
      'altura': altura,
      'eliminado': eliminado,
      'email': email,
      'telefono': telefono,
      'observaciones': observaciones,
      'localidad': localidad,
      'barrio': barrio,
      'provincia': provincia,
      'direccion': direccion,
      'dni': dni,
      'status': status,
      'image': image,
      'wc_customer_id': wcCustomerId,
      'activo': activo, // Añadir estado en la serialización
    };
  }

  // Método toMap
  Map<String, dynamic> toMap() {
    return {
      'creador_id': creadorId,
      'id_cliente': idCliente,
      'nombre': nombre,
      'sucursal_id': sucursalId,
      'lista_precio': listaPrecio,
      'comercio_id': comercioId,
      'last_sale': lastSale?.toIso8601String(),
      'recontacto': recontacto?.toIso8601String(),
      'plazo_cuenta_corriente': plazoCuentaCorriente,
      'monto_maximo_cuenta_corriente': montoMaximoCuentaCorriente,
      'saldo_inicial_cuenta_corriente': saldoInicialCuentaCorriente,
      'fecha_inicial_cuenta_corriente': fechaInicialCuentaCorriente?.toIso8601String(),
      'pais': pais,
      'codigo_postal': codigoPostal,
      'depto': depto,
      'piso': piso,
      'altura': altura,
      'eliminado': eliminado,
      'email': email,
      'telefono': telefono,
      'observaciones': observaciones,
      'localidad': localidad,
      'barrio': barrio,
      'provincia': provincia,
      'direccion': direccion,
      'dni': dni,
      'status': status,
      'image': image,
      'wc_customer_id': wcCustomerId,
      'activo': activo, // Añadir estado en el mapeo
    };
  }
}
