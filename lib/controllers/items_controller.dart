import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

import '../services/items_service.dart';
import '../services/websocket_service.dart';
import '../services/notification_service.dart';

/// Controlador para manejar operaciones relacionadas con items
class ItemsController {
  final _logger = Logger('ItemsController');
  final _itemsService = ItemsService();
  final _wsService = WebSocketService();
  final _notificationService = NotificationService();

  /// Obtiene todos los items para un espacio específico
  Future<Response> getItemsBySpaceId(Request request, String spaceId) async {
    try {
      final spaceIdInt = int.tryParse(spaceId);
      if (spaceIdInt == null) {
        return Response(400, 
          body: jsonEncode({'error': 'ID de espacio inválido'}),
          headers: {'content-type': 'application/json'});
      }
      
      final items = await _itemsService.getItemsBySpaceId(spaceIdInt);
      
      return Response.ok(
        jsonEncode({
          'items': items.map((item) => item.toMap()).toList(),
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener items para espacio', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al obtener items para espacio'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Crea un nuevo item para un espacio
  Future<Response> createItem(Request request, String spaceId) async {
    try {
      final spaceIdInt = int.tryParse(spaceId);
      if (spaceIdInt == null) {
        return Response(400, 
          body: jsonEncode({'error': 'ID de espacio inválido'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Verificar si el usuario tiene permisos para administrar inventario
      final userRole = request.context['userRole'] as String;
      
      // Solo usuarios con permiso pueden crear items
      if (userRole.length <= 11 || userRole[11] != '1') {
        return Response(403, 
          body: jsonEncode({'error': 'No tiene permisos para administrar inventario'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Obtener el usuario del contexto
      final userName = request.context['userName'] as String;
      
      // Leer el cuerpo de la solicitud
      final String body = await request.readAsString();
      final Map<String, dynamic> data = jsonDecode(body);
      
      // Validar datos requeridos
      if (!data.containsKey('nombre') || data['nombre'] == null ||
          !data.containsKey('cantidad_esperada') || data['cantidad_esperada'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Se requieren nombre y cantidad_esperada'}),
          headers: {'content-type': 'application/json'});
      }
      
      final String name = data['nombre'];
      final int expectedQuantity = data['cantidad_esperada'];
      
      // Crear el item
      final item = await _itemsService.createItem(
        spaceId: spaceIdInt,
        name: name,
        expectedQuantity: expectedQuantity,
      );
      
      if (item == null) {
        return Response(500, 
          body: jsonEncode({'error': 'Error al crear el item'}),
          headers: {'content-type': 'application/json'});
      }
      
      _logger.info('Item creado por $userName: ${item.name} (ID: ${item.id})');
      
      // Enviar notificación WebSocket usando el servicio centralizado
      _notificationService.notifyInventoryUpdate(
        action: 'create',
        spaceId: spaceIdInt,
        itemId: item.id,
        itemName: item.name,
        expectedQuantity: item.expectedQuantity,
        createdBy: userName
      );
      
      // Registrar en el log el envío de la notificación
      _logger.info('Notificación WebSocket enviada para nuevo ítem ${item.id} en espacio $spaceIdInt');
      
      return Response.ok(
        jsonEncode({'item': item.toMap()}),
        headers: {'content-type': 'application/json'});
    } catch (e, stackTrace) {
      _logger.severe('Error al crear item', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al crear item'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Actualiza un item existente
  Future<Response> updateItem(Request request, String id) async {
    try {
      final itemId = int.tryParse(id);
      if (itemId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'ID de item inválido'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Verificar si el usuario tiene permisos para administrar inventario
      final userRole = request.context['userRole'] as String;
      
      // Solo usuarios con permiso pueden actualizar items
      if (userRole.length <= 11 || userRole[11] != '1') {
        return Response(403, 
          body: jsonEncode({'error': 'No tiene permisos para administrar inventario'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Obtener el usuario del contexto
      final userName = request.context['userName'] as String;
      
      // Leer el cuerpo de la solicitud
      final String body = await request.readAsString();
      final Map<String, dynamic> data = jsonDecode(body);
      
      // Validar datos requeridos
      if (!data.containsKey('nombre') || data['nombre'] == null ||
          !data.containsKey('cantidad_esperada') || data['cantidad_esperada'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Se requieren nombre y cantidad_esperada'}),
          headers: {'content-type': 'application/json'});
      }
      
      final String name = data['nombre'];
      final int expectedQuantity = data['cantidad_esperada'];
      
      // Obtener el item original para saber su spaceId
      final originalItem = await _itemsService.getItemById(itemId);
      if (originalItem == null) {
        return Response(404, 
          body: jsonEncode({'error': 'Item no encontrado'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Actualizar el item
      final item = await _itemsService.updateItem(
        id: itemId,
        name: name,
        expectedQuantity: expectedQuantity,
      );
      
      if (item == null) {
        return Response(500, 
          body: jsonEncode({'error': 'Error al actualizar el item'}),
          headers: {'content-type': 'application/json'});
      }
      
      _logger.info('Item actualizado por $userName: ${item.name} (ID: ${item.id})');
      
      // Enviar notificación WebSocket usando el servicio centralizado
      _notificationService.notifyInventoryUpdate(
        action: 'update',
        spaceId: originalItem.spaceId,
        itemId: item.id,
        itemName: item.name,
        expectedQuantity: item.expectedQuantity,
        updatedBy: userName
      );
      
      return Response.ok(
        jsonEncode({'item': item.toMap()}),
        headers: {'content-type': 'application/json'});
    } catch (e, stackTrace) {
      _logger.severe('Error al actualizar item', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al actualizar item'}),
        headers: {'content-type': 'application/json'});
    }
  }

  /// Elimina un item existente
  Future<Response> deleteItem(Request request, String id) async {
    try {
      final itemId = int.tryParse(id);
      if (itemId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'ID de item inválido'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Verificar si el usuario tiene permisos para administrar inventario
      final userRole = request.context['userRole'] as String;
      
      // Solo usuarios con permiso pueden eliminar items
      if (userRole.length <= 11 || userRole[11] != '1') {
        return Response(403, 
          body: jsonEncode({'error': 'No tiene permisos para administrar inventario'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Obtener el usuario del contexto
      final userName = request.context['userName'] as String;
      
      // Obtener el item original para saber su spaceId
      final originalItem = await _itemsService.getItemById(itemId);
      if (originalItem == null) {
        return Response(404, 
          body: jsonEncode({'error': 'Item no encontrado'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Eliminar el item
      final success = await _itemsService.deleteItem(itemId);
      
      if (!success) {
        return Response(500, 
          body: jsonEncode({'error': 'Error al eliminar el item'}),
          headers: {'content-type': 'application/json'});
      }
      
      _logger.info('Item eliminado por $userName: ID $itemId');
      
      // Enviar notificación WebSocket usando el servicio centralizado
      _notificationService.notifyInventoryUpdate(
        action: 'delete',
        spaceId: originalItem.spaceId,
        itemId: itemId,
        deletedBy: userName
      );
      
      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'content-type': 'application/json'});
    } catch (e, stackTrace) {
      _logger.severe('Error al eliminar item', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al eliminar item'}),
        headers: {'content-type': 'application/json'});
    }
  }
}
