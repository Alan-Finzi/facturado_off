import 'package:equatable/equatable.dart';

/// Modelo para representar un pago parcial en un pago dividido
class PagoParcial extends Equatable {
  /// ID del tipo de cobro seleccionado
  final int? tipoCobroId;

  /// Nombre del tipo de cobro (Efectivo, Tarjeta, etc.)
  final String? tipoCobroNombre;

  /// ID de la forma de cobro seleccionada
  final int? formaCobroId;

  /// Nombre de la forma de cobro
  final String? formaCobroNombre;

  /// Monto del pago parcial
  final double montoPago;

  /// Porcentaje de recargo aplicado a este pago
  final double porcentajeRecargo;

  /// Recargo calculado en pesos
  final double montoRecargo;

  /// Constructor
  PagoParcial({
    this.tipoCobroId,
    this.tipoCobroNombre,
    this.formaCobroId,
    this.formaCobroNombre,
    required this.montoPago,
    required this.porcentajeRecargo,
  }) : montoRecargo = (porcentajeRecargo / 100) * montoPago;

  /// Getter para obtener el monto total con recargo
  double get montoTotal => montoPago + montoRecargo;

  /// Lista de propiedades para Equatable
  @override
  List<Object?> get props => [
    tipoCobroId,
    tipoCobroNombre,
    formaCobroId,
    formaCobroNombre,
    montoPago,
    porcentajeRecargo,
    montoRecargo
  ];

  /// Crear copia con algunas propiedades modificadas
  PagoParcial copyWith({
    int? tipoCobroId,
    String? tipoCobroNombre,
    int? formaCobroId,
    String? formaCobroNombre,
    double? montoPago,
    double? porcentajeRecargo,
  }) {
    return PagoParcial(
      tipoCobroId: tipoCobroId ?? this.tipoCobroId,
      tipoCobroNombre: tipoCobroNombre ?? this.tipoCobroNombre,
      formaCobroId: formaCobroId ?? this.formaCobroId,
      formaCobroNombre: formaCobroNombre ?? this.formaCobroNombre,
      montoPago: montoPago ?? this.montoPago,
      porcentajeRecargo: porcentajeRecargo ?? this.porcentajeRecargo,
    );
  }

  /// Convertir a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'tipo_cobro_id': tipoCobroId,
      'tipo_cobro_nombre': tipoCobroNombre,
      'forma_cobro_id': formaCobroId,
      'forma_cobro_nombre': formaCobroNombre,
      'monto_pago': montoPago,
      'porcentaje_recargo': porcentajeRecargo,
      'monto_recargo': montoRecargo,
    };
  }

  /// Crear desde Map
  factory PagoParcial.fromMap(Map<String, dynamic> map) {
    return PagoParcial(
      tipoCobroId: map['tipo_cobro_id'],
      tipoCobroNombre: map['tipo_cobro_nombre'],
      formaCobroId: map['forma_cobro_id'],
      formaCobroNombre: map['forma_cobro_nombre'],
      montoPago: map['monto_pago'] as double,
      porcentajeRecargo: map['porcentaje_recargo'] as double,
    );
  }

  /// Para debugging
  @override
  String toString() {
    return 'PagoParcial{tipoCobroNombre: $tipoCobroNombre, formaCobroNombre: $formaCobroNombre, montoPago: $montoPago, porcentajeRecargo: $porcentajeRecargo%, montoRecargo: $montoRecargo}';
  }
}