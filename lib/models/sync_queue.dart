import 'package:flutter/foundation.dart';

/// Modelo para representar elementos en la cola de sincronización
///
/// Esta clase se utiliza para llevar registro de recursos que
/// necesitan ser sincronizados con el servidor remoto cuando
/// haya conexión disponible.
class SyncQueue {
  /// ID único de la entrada en la cola (autogenerado)
  final int? id;

  /// Tipo de recurso (ej: "payment_method", "payment_provider")
  final String resourceType;

  /// ID del recurso
  final int resourceId;

  /// Operación a realizar ("upsert", "delete")
  final String operation;

  /// Payload en formato JSON string
  final String payload;

  /// Estado de la sincronización ("pending", "syncing", "done", "failed")
  final String status;

  /// Fecha de creación
  final String createdAt;

  /// Cantidad de intentos realizados
  final int? attempts;

  /// Último mensaje de error (si existe)
  final String? errorMessage;

  SyncQueue({
    this.id,
    required this.resourceType,
    required this.resourceId,
    required this.operation,
    required this.payload,
    required this.status,
    required this.createdAt,
    this.attempts = 0,
    this.errorMessage,
  });

  /// Crea una instancia desde un mapa JSON
  factory SyncQueue.fromJson(Map<String, dynamic> json) {
    return SyncQueue(
      id: json['id'],
      resourceType: json['resource_type'] ?? '',
      resourceId: json['resource_id'] ?? 0,
      operation: json['operation'] ?? 'upsert',
      payload: json['payload'] ?? '{}',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      attempts: json['attempts'] ?? 0,
      errorMessage: json['error_message'],
    );
  }

  /// Convierte la instancia a un mapa para almacenar en la base de datos
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'resource_type': resourceType,
      'resource_id': resourceId,
      'operation': operation,
      'payload': payload,
      'status': status,
      'created_at': createdAt,
      'attempts': attempts,
      'error_message': errorMessage,
    };
  }

  /// Crea una copia con algunos campos actualizados
  SyncQueue copyWith({
    int? id,
    String? resourceType,
    int? resourceId,
    String? operation,
    String? payload,
    String? status,
    String? createdAt,
    int? attempts,
    String? errorMessage,
  }) {
    return SyncQueue(
      id: id ?? this.id,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Incrementa el contador de intentos
  SyncQueue incrementAttempt([String? newErrorMessage]) {
    return copyWith(
      attempts: (attempts ?? 0) + 1,
      errorMessage: newErrorMessage ?? errorMessage,
    );
  }

  /// Marca como en proceso de sincronización
  SyncQueue markAsSyncing() {
    return copyWith(status: 'syncing');
  }

  /// Marca como sincronizado correctamente
  SyncQueue markAsCompleted() {
    return copyWith(status: 'done');
  }

  /// Marca como fallido con un mensaje de error
  SyncQueue markAsFailed(String errorMessage) {
    return copyWith(
      status: 'failed',
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    return 'SyncQueue{id: $id, resourceType: $resourceType, resourceId: $resourceId, status: $status}';
  }
}