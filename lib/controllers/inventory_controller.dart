import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

import '../models/inventory_item.dart';
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

  /// Obtiene el inventario completo (espacios, ítems y cantidades) para una casa específica
  /// Este endpoint optimizado obtiene todos los datos necesarios en una sola consulta
  Future<Response> getFullInventoryForHouse(Request request, String houseId) async {
    try {
      final houseIdInt = int.tryParse(houseId);
      if (houseIdInt == null) {
        return Response(400, 
          body: jsonEncode({'error': 'ID de casa inválido'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Usar la función optimizada que devuelve todos los datos en una sola consulta
      final result = await _inventoryService.getFullInventoryForHouse(houseIdInt);
      
      return Response.ok(
        jsonEncode(result),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener inventario completo para casa', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al obtener inventario completo para casa'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }
  
  /// Obtiene el resumen de completitud para una casa específica
  /// Utiliza la vista materializada para resultados más rápidos
  Future<Response> getInventorySummary(Request request, String houseId) async {
    try {
      final houseIdInt = int.tryParse(houseId);
      if (houseIdInt == null) {
        return Response(400, 
          body: jsonEncode({'error': 'ID de casa inválido'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Usar la vista materializada para obtener el resumen
      final summary = await _inventoryService.getInventorySummary(houseIdInt);
      
      if (summary == null) {
        return Response.notFound(
          jsonEncode({'error': 'No se encontró resumen para la casa especificada'}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      return Response.ok(
        jsonEncode(summary),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener resumen de inventario', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al obtener resumen de inventario'}),
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
          !data.containsKey('quantity') || data['quantity'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Se requieren house_id, item_id y quantity'}),
          headers: {'content-type': 'application/json'});
      }
      
      final int houseId = data['house_id'];
      final int itemId = data['item_id'];
      final int quantity = data['quantity'];
      
      // Crear el elemento de inventario
      final item = await _inventoryService.createInventoryItem(
        houseId: houseId,
        itemId: itemId,
        quantity: quantity,
        status: "active", // Valor por defecto para mantener compatibilidad
        createdBy: userName,
      );
      
      if (item == null) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Error al crear elemento de inventario'}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      _logger.info('Elemento de inventario creado por $userName para casa $houseId e item $itemId');
      
      return Response.ok(
        jsonEncode({
          'success': true,
          'item': item.toMap(),
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

  /// Actualiza un elemento de inventario por ID
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
      if (!data.containsKey('quantity')) {
        return Response(400, 
          body: jsonEncode({'error': 'Se requiere al menos el campo quantity para actualizar'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Actualizar el elemento de inventario
      final success = await _inventoryService.updateInventoryItem(
        id: itemId,
        quantity: data['quantity'],
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

  /// Actualiza un elemento de inventario por casa e item ID
  Future<Response> updateHouseInventoryItem(Request request, String houseId, String itemId) async {
    try {
      final houseIdInt = int.tryParse(houseId);
      final itemIdInt = int.tryParse(itemId);
      
      if (houseIdInt == null || itemIdInt == null) {
        return Response(400, 
          body: jsonEncode({'error': 'ID de casa o item inválido'}),
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
      if (!data.containsKey('cantidad') && !data.containsKey('quantity')) {
        return Response(400, 
          body: jsonEncode({'error': 'Se requiere el campo cantidad o quantity para actualizar'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Obtener la cantidad del campo 'cantidad' o 'quantity'
      final quantity = data.containsKey('cantidad') ? data['cantidad'] : data['quantity'];
      
      // Buscar el ID del registro en house_inventory
      final inventoryItems = await _inventoryService.getInventoryForHouse(houseIdInt);
      
      // Buscar manualmente el item en lugar de usar firstWhere con orElse
      InventoryItem? item;
      for (var invItem in inventoryItems) {
        if (invItem.itemId == itemIdInt) {
          item = invItem;
          break;
        }
      }
      
      if (item == null) {
        // Si no existe, crear un nuevo registro
        final newItem = await _inventoryService.createInventoryItem(
          houseId: houseIdInt,
          itemId: itemIdInt,
          quantity: quantity,
          status: "active",
          createdBy: userName,
        );
        
        if (newItem == null) {
          return Response.internalServerError(
            body: jsonEncode({'error': 'Error al crear el elemento de inventario'}),
            headers: {'content-type': 'application/json'}
          );
        }
        
        _logger.info('Elemento de inventario creado por $userName para casa $houseIdInt e item $itemIdInt');
        
        return Response.ok(
          jsonEncode({
            'success': true,
            'message': 'Elemento de inventario creado correctamente',
            'item': newItem.toMap(),
          }),
          headers: {'content-type': 'application/json'}
        );
      } else {
        // Si existe, actualizar el registro
        final success = await _inventoryService.updateInventoryItem(
          id: item.id!,
          quantity: quantity,
          updatedBy: userName,
        );
        
        if (!success) {
          return Response.internalServerError(
            body: jsonEncode({'error': 'Error al actualizar el elemento de inventario'}),
            headers: {'content-type': 'application/json'}
          );
        }
        
        _logger.info('Elemento de inventario ${item.id} actualizado por $userName');
        
        return Response.ok(
          jsonEncode({
            'success': true,
            'message': 'Elemento de inventario actualizado correctamente',
          }),
          headers: {'content-type': 'application/json'}
        );
      }
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

  /// Obtiene el inventario para múltiples casas
  Future<Response> getInventoryForMultipleHouses(Request request) async {
    try {
      // Leer el cuerpo de la solicitud
      final String body = await request.readAsString();
      final Map<String, dynamic> data = jsonDecode(body);
      
      // Validar datos requeridos
      if (!data.containsKey('house_ids') || data['house_ids'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Se requiere house_ids'}),
          headers: {'content-type': 'application/json'});
      }
      
      final List<int> houseIds = List<int>.from(data['house_ids']);
      
      if (houseIds.isEmpty) {
        return Response.ok(
          jsonEncode({}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      // Obtener inventario para múltiples casas
      final result = <String, List<Map<String, dynamic>>>{};
      
      for (final houseId in houseIds) {
        final inventory = await _inventoryService.getInventoryForHouse(houseId);
        result[houseId.toString()] = inventory.map((item) => item.toMap()).toList();
      }
      
      return Response.ok(
        jsonEncode(result),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener inventario para múltiples casas', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al obtener inventario para múltiples casas'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Obtiene el porcentaje de completitud del inventario para una casa
  Future<Response> getCompletionPercentage(Request request, String houseId) async {
    try {
      final houseIdInt = int.tryParse(houseId);
      if (houseIdInt == null) {
        return Response(400, 
          body: jsonEncode({'error': 'ID de casa inválido'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Obtener inventario para la casa
      final inventory = await _inventoryService.getInventoryForHouse(houseIdInt);
      
      // Si no hay inventario, devolver 0%
      if (inventory.isEmpty) {
        return Response.ok(
          jsonEncode({'percentage': 0.0}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      // Calcular porcentaje de completitud
      // Por ahora, simplemente calculamos cuántos items tienen cantidad > 0
      int itemsWithQuantity = 0;
      for (final item in inventory) {
        if (item.quantity > 0) {
          itemsWithQuantity++;
        }
      }
      
      final percentage = inventory.isEmpty ? 0.0 : (itemsWithQuantity / inventory.length) * 100;
      
      return Response.ok(
        jsonEncode({'percentage': percentage}),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener porcentaje de completitud', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al obtener porcentaje de completitud'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Obtiene el porcentaje de completitud del inventario para múltiples casas
  Future<Response> getCompletionPercentageForMultipleHouses(Request request) async {
    try {
      // Leer el cuerpo de la solicitud
      final String body = await request.readAsString();
      final Map<String, dynamic> data = jsonDecode(body);
      
      // Validar datos requeridos
      if (!data.containsKey('house_ids') || data['house_ids'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Se requiere house_ids'}),
          headers: {'content-type': 'application/json'});
      }
      
      final List<int> houseIds = List<int>.from(data['house_ids']);
      
      if (houseIds.isEmpty) {
        return Response.ok(
          jsonEncode({}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      // Obtener porcentaje de completitud para múltiples casas
      final result = <String, double>{};
      
      for (final houseId in houseIds) {
        // Obtener inventario para la casa
        final inventory = await _inventoryService.getInventoryForHouse(houseId);
        
        // Si no hay inventario, devolver 0%
        if (inventory.isEmpty) {
          result[houseId.toString()] = 0.0;
          continue;
        }
        
        // Calcular porcentaje de completitud
        int itemsWithQuantity = 0;
        for (final item in inventory) {
          if (item.quantity > 0) {
            itemsWithQuantity++;
          }
        }
        
        final percentage = inventory.isEmpty ? 0.0 : (itemsWithQuantity / inventory.length) * 100;
        result[houseId.toString()] = percentage;
      }
      
      return Response.ok(
        jsonEncode(result),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener porcentaje de completitud para múltiples casas', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al obtener porcentaje de completitud para múltiples casas'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }
} 