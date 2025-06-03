class ClientesMostrador {
  static ClientesMostrador currentCompany = ClientesMostrador();
  final int? creadorId;
  final String? idCliente;
  final String? nombre;
  final int? sucursalId;
  final int? listaPrecio;
  final int? comercioId;
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
    try {
      double montoMaximo = 0.0;
      try {
        final dynamic raw = json['monto_maximo_cuenta_corriente'];
        if (raw != null) {
          if (raw is double) {
            montoMaximo = raw;
          } else if (raw is int) {
            montoMaximo = raw.toDouble();
          } else if (raw is String) {
            montoMaximo = double.tryParse(raw) ?? 0.0;
          } else {
            print('Tipo inesperado en "monto_maximo_cuenta_corriente" del cliente ${json['id_cliente']}: ${raw.runtimeType}');
          }
        }
      } catch (e) {
        print('Error en campo "monto_maximo_cuenta_corriente" del cliente ${json['id_cliente']}: $e');
      }

      double saldoInicial = 0.0;
      try {
        saldoInicial = json['saldo_inicial_cuenta_corriente'] != null
            ? double.tryParse(json['saldo_inicial_cuenta_corriente'].toString()) ?? 0.0
            : 0.0;
      } catch (e) {
        print('Error en campo "saldo_inicial_cuenta_corriente" del cliente ${json['id_cliente']}: $e');
      }

      DateTime? fechaInicial;
      try {
        fechaInicial = json['fecha_inicial_cuenta_corriente'] != null
            ? DateTime.parse(json['fecha_inicial_cuenta_corriente'])
            : null;
      } catch (e) {
        print('Error en campo "fecha_inicial_cuenta_corriente" del cliente ${json['id_cliente']}: $e');
      }

      return ClientesMostrador(
        creadorId: json['creador_id'],
        idCliente: json['id_cliente'].toString(),
        nombre: json['nombre'],
        sucursalId: json['sucursal_id'],
        listaPrecio: json['lista_precio'],
        comercioId: json['comercio_id'],
        plazoCuentaCorriente: json['plazo_cuenta_corriente'],
        montoMaximoCuentaCorriente: montoMaximo,
        saldoInicialCuentaCorriente: saldoInicial,
        fechaInicialCuentaCorriente: fechaInicial,
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
        activo: json['activo'] ?? 1,
      );
    } catch (e) {
      print('Error general al deserializar cliente con ID: ${json['id_cliente']}, error: $e');
      rethrow;
    }
  }



  Map<String, dynamic> toJson() {
    return {
      'creador_id': creadorId,
      'id_cliente': idCliente,
      'nombre': nombre,
      'sucursal_id': sucursalId,
      'lista_precio': listaPrecio,
      'comercio_id': comercioId,
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
