import 'dart:io';
import 'services/notification_service.dart';
import 'services/websocket_service.dart';

/// Script para probar el sistema centralizado de notificaciones WebSocket
void main() async {
  print('Iniciando prueba de WebSocket...');
  
  // Crear instancia del servicio de notificaciones
  final notificationService = NotificationService();
  
  // Esperar a que el usuario presione Enter para enviar una notificación de prueba
  print('Presiona Enter para enviar una notificación de prueba a las casas...');
  stdin.readLineSync();
  
  // Enviar notificación de prueba para casas
  notificationService.notifyHouseUpdate(
    houseId: 1,
    action: 'update_status',
    status: 'clean',
    updatedBy: 'test_script'
  );
  print('Notificación enviada a tópico houses');
  
  // Esperar a que el usuario presione Enter para enviar una notificación de prueba
  print('Presiona Enter para enviar una notificación de prueba a las notas...');
  stdin.readLineSync();
  
  // Enviar notificación de prueba para notas
  notificationService.notifyNoteUpdate(
    action: 'create',
    noteData: {
      'id': 9999,
      'house_id': 1,
      'content': 'Nota de prueba desde script',
      'category': 'general',
      'area': 'living',
      'created_at': DateTime.now().toIso8601String(),
      'created_by': 'test_script',
      'house_name': 'Casa de Prueba',
      'house_type': 'indoor'
    },
    createdBy: 'test_script'
  );
  print('Notificación enviada a tópico notes');
  
  // Esperar a que el usuario presione Enter para enviar una notificación de prueba
  print('Presiona Enter para enviar una notificación de prueba a las tareas...');
  stdin.readLineSync();
  
  // Enviar notificación de prueba para tareas
  notificationService.notifyTaskUpdate(
    action: 'complete',
    taskId: 1,
    taskType: 'Limpiar casa',
    houseId: 1,
    houseName: 'Casa de Prueba',
    completedBy: 'test_script'
  );
  print('Notificación enviada a tópico tasks');
  
  // Esperar a que el usuario presione Enter para salir
  print('Presiona Enter para salir...');
  stdin.readLineSync();
  
  print('Prueba finalizada');
  exit(0);
} 