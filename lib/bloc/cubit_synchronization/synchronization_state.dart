part of 'synchronization_cubit.dart';


sealed class SynchronizationState extends Equatable {
  const SynchronizationState();
}

// Estado inicial
final class SynchronizationInitial extends SynchronizationState {
  @override
  List<Object> get props => [];
}

// Estado de progreso
final class SynchronizationInProgress extends SynchronizationState {
  final double progress;
  final String currentTask;

  const SynchronizationInProgress({required this.progress, required this.currentTask});

  @override
  List<Object> get props => [progress, currentTask];
}

// Estado de sincronización completada
final class SynchronizationCompleted extends SynchronizationState {
  @override
  List<Object> get props => [];
}

// Estado de sincronización fallida
final class SynchronizationFailed extends SynchronizationState {
  final String errorMessage;

  const SynchronizationFailed({required this.errorMessage});

  @override
  List<Object> get props => [errorMessage];
}