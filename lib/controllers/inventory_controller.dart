import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

import '../services/inventory_service.dart';

/// Controlador para manejar operaciones relacionadas con inventario
class InventoryController {
  final _logger = Logger('InventoryController');
  final _inventoryService = InventoryService();

  /// Obtiene todo el inventario
  Future<Response> getAllInventory(Request request) async {
    try {
      final inventory = await _inventoryService.getAllInventory();
      
      return Response.ok(
        jsonEncode({
          'inventory': inventory.map((item) => item.toMap()).toList(),
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener inventario', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al obtener inventario'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Obtiene el inventario para una casa específica
  Future<Response> getInventoryForHouse(Request request, String houseId) async {
    try {
      final houseIdInt = int.tryParse(houseId);
      if (houseIdInt == null) {
        return Response(400, 
          body: jsonEncode({'error': 'ID de casa inválido'}),
          headers: {'content-type': 'application/json'});
      }
      
      final inventory = await _inventoryService.getInventoryForHouse(houseIdInt);
      
      return Response.ok(
        jsonEncode({
          'inventory': inventory.map((item) => item.toMap()).toList(),
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener inventario para casa', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al obtener inventario para casa'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Crea un nuevo elemento de inventario
  Future<Response> createInventoryItem(Request request) async {
    try {
      // Verificar si el usuario tiene permisos para administrar inventario
      final userRole = request.context['userRole'] as String;
      
      // Solo usuarios con permiso pueden crear elementos de inventario
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
      if (!data.containsKey('house_id') || data['house_id'] == null ||
          !data.containsKey('item_id') || data['item_id'] == null ||
          !data.containsKey('quantity') || data['quantity'] == null ||
          !data.containsKey('status') || data['status'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Se requieren house_id, item_id, quantity y status'}),
          headers: {'content-type': 'application/json'});
      }
      
      final int houseId = data['house_id'];
      final int itemId = data['item_id'];
      final int quantity = data['quantity'];
      final String status = data['status'];
      
      // Crear el elemento de inventario
      final item = await _inventoryService.createInventoryItem(
        houseId: houseId,
        itemId: itemId,
        quantity: quantity,
        status: status,
        createdBy: userName,
      );
      
      if (item == null) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Error al crear el elemento de inventario'}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      _logger.info('Elemento de inventario creado para casa $houseId por $userName');
      
      return Response.ok(
        jsonEncode({
          'success': true,
          'inventory_item': item.toMap(),
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al crear elemento de inventario', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al crear elemento de inventario'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Actualiza un elemento de inventario
  Future<Response> updateInventoryItem(Request request, String id) async {
    try {
      final itemId = int.tryParse(id);
      if (itemId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'ID de elemento inválido'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Verificar si el usuario tiene permisos para administrar inventario
      final userRole = request.context['userRole'] as String;
      
      // Solo usuarios con permiso pueden actualizar elementos de inventario
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
      
      // Validar que al menos un campo a actualizar esté presente
      if (!data.containsKey('quantity') && !data.containsKey('status')) {
        return Response(400, 
          body: jsonEncode({'error': 'Se requiere al menos un campo para actualizar (quantity o status)'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Actualizar el elemento de inventario
      final success = await _inventoryService.updateInventoryItem(
        id: itemId,
        quantity: data['quantity'],
        status: data['status'],
        updatedBy: userName,
      );
      
      if (!success) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Error al actualizar el elemento de inventario'}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      _logger.info('Elemento de inventario $itemId actualizado por $userName');
      
      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Elemento de inventario actualizado correctamente',
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al actualizar elemento de inventario', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al actualizar elemento de inventario'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Elimina un elemento de inventario
  Future<Response> deleteInventoryItem(Request request, String id) async {
    try {
      final itemId = int.tryParse(id);
      if (itemId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'ID de elemento inválido'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Verificar si el usuario tiene permisos para administrar inventario
      final userRole = request.context['userRole'] as String;
      
      // Solo usuarios con permiso pueden eliminar elementos de inventario
      if (userRole.length <= 11 || userRole[11] != '1') {
        return Response(403, 
          body: jsonEncode({'error': 'No tiene permisos para administrar inventario'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Obtener el usuario del contexto
      final userName = request.context['userName'] as String;
      
      // Eliminar el elemento de inventario
      final success = await _inventoryService.deleteInventoryItem(itemId);
      
      if (!success) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Error al eliminar el elemento de inventario'}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      _logger.info('Elemento de inventario $itemId eliminado por $userName');
      
      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Elemento de inventario eliminado correctamente',
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al eliminar elemento de inventario', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al eliminar elemento de inventario'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }
} 