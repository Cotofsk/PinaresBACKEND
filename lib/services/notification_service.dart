import 'package:logging/logging.dart';
import 'dart:convert';
import 'package:shelf/shelf.dart';

import 'websocket_service.dart';

/// Servicio centralizado para manejar todas las notificaciones WebSocket
/// Este servicio actúa como punto único para enviar notificaciones a los clientes
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final _logger = Logger('NotificationService');
  final WebSocketService _wsService = WebSocketService();
  
  // Singleton pattern
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();

  /// Notifica a los clientes sobre una actualización de casa
  void notifyHouseUpdate({
    required int houseId,
    required String action,
    Map<String, dynamic>? houseData,
    Map<String, dynamic>? changes,
    String? status,
    String? checks,
    String? updatedBy,
  }) {
    final payload = <String, dynamic>{
      'action': action,
      'entity': 'house',
      'id': houseId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (houseData != null) {
      payload['house'] = houseData;
    }

    if (changes != null) {
      payload['changes'] = changes;
    }

    if (status != null) {
      payload['status'] = status;
    }

    if (checks != null) {
      payload['checks'] = checks;
    }

    if (updatedBy != null) {
      payload['updated_by'] = updatedBy;
    }

    _wsService.notifyTopic(WebSocketService.TOPIC_HOUSES, payload);
    _logger.info('Notificación enviada a tópico houses: ${jsonEncode(payload)}');
  }

  /// Notifica a los clientes sobre una actualización de nota
  void notifyNoteUpdate({
    required String action,
    int? noteId,
    int? houseId,
    Map<String, dynamic>? noteData,
    String? createdBy,
    String? deletedBy,
  }) {
    final payload = <String, dynamic>{
      'action': action,
      'entity': 'note',
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (noteId != null) {
      payload['note_id'] = noteId;
    }

    if (houseId != null) {
      payload['house_id'] = houseId;
    }

    if (noteData != null) {
      payload['note'] = noteData;
    }

    if (createdBy != null) {
      payload['created_by'] = createdBy;
    }

    if (deletedBy != null) {
      payload['deleted_by'] = deletedBy;
    }

    _wsService.notifyTopic(WebSocketService.TOPIC_NOTES, payload);
    _logger.info('Notificación enviada a tópico notes: ${jsonEncode(payload)}');
  }

  /// Notifica a los clientes sobre una actualización de tarea
  void notifyTaskUpdate({
    required String action,
    int? taskId,
    Map<String, dynamic>? taskData,
    List<int>? assignedUserIds,
    String? taskType,
    int? houseId,
    String? houseName,
    String? createdBy,
    String? updatedBy,
    String? completedBy,
  }) {
    final payload = <String, dynamic>{
      'action': action,
      'entity': 'task',
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (taskId != null) {
      payload['task_id'] = taskId;
    }

    if (taskData != null) {
      payload['task'] = taskData;
    }

    if (assignedUserIds != null) {
      payload['assigned_user_ids'] = assignedUserIds;
    }

    if (taskType != null) {
      payload['task_type'] = taskType;
    }

    if (houseId != null) {
      payload['house_id'] = houseId;
    }

    if (houseName != null) {
      payload['house_name'] = houseName;
    }

    if (createdBy != null) {
      payload['created_by'] = createdBy;
    }

    if (updatedBy != null) {
      payload['updated_by'] = updatedBy;
    }

    if (completedBy != null) {
      payload['completed_by'] = completedBy;
    }

    _wsService.notifyTopic(WebSocketService.TOPIC_TASKS, payload);
    _logger.info('Notificación enviada a tópico tasks: ${jsonEncode(payload)}');
  }

  /// Notifica a los clientes sobre una actualización de inventario
  void notifyInventoryUpdate({
    required String action,
    required int spaceId,
    int? itemId,
    String? itemName,
    int? expectedQuantity,
    String? createdBy,
    String? updatedBy,
    String? deletedBy,
  }) {
    final payload = <String, dynamic>{
      'action': action,
      'space_id': spaceId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (itemId != null) {
      payload['item_id'] = itemId;
    }

    if (itemName != null) {
      payload['item_name'] = itemName;
    }

    if (expectedQuantity != null) {
      payload['expected_quantity'] = expectedQuantity;
    }

    if (createdBy != null) {
      payload['created_by'] = createdBy;
    }

    if (updatedBy != null) {
      payload['updated_by'] = updatedBy;
    }

    if (deletedBy != null) {
      payload['deleted_by'] = deletedBy;
    }

    _wsService.notifyTopic(WebSocketService.TOPIC_INVENTORY, payload);
    _logger.info('Notificación enviada a tópico inventory: ${jsonEncode(payload)}');
  }

  /// Notifica a los clientes con un payload personalizado a un tópico específico
  void notifyCustom(String topic, Map<String, dynamic> payload) {
    _wsService.notifyTopic(topic, payload);
    _logger.info('Notificación personalizada enviada a tópico $topic: ${jsonEncode(payload)}');
  }
} 