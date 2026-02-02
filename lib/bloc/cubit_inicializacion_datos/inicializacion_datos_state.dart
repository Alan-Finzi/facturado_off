part of 'inicializacion_datos_cubit.dart';

abstract class InicializacionDatosState extends Equatable {
  const InicializacionDatosState();

  @override
  List<Object?> get props => [];
}

class InicializacionDatosInicial extends InicializacionDatosState {}

class InicializacionDatosEnProgreso extends InicializacionDatosState {
  final String mensaje;
  final double progreso;

  const InicializacionDatosEnProgreso({required this.mensaje, this.progreso = 0.0});

  @override
  List<Object?> get props => [mensaje, progreso];
}

class InicializacionDatosExitosa extends InicializacionDatosState {}

class InicializacionDatosError extends InicializacionDatosState {
  final String mensaje;

  const InicializacionDatosError(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}