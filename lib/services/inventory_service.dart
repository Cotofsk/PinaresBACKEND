import 'package:logging/logging.dart';

import '../models/inventory_item.dart';
import 'database_service.dart';

/// Servicio para manejar operaciones de inventario
class InventoryService {
  final _logger = Logger('InventoryService');
  final _dbService = DatabaseService();

  /// Obtiene todos los elementos de inventario
  Future<List<InventoryItem>> getAllInventory() async {
    try {
      final result = await _dbService.query(
        'SELECT * FROM house_inventory ORDER BY house_id, item_id',
      );
      
      return result.map((row) => InventoryItem.fromMap(row)).toList();
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener inventario', e, stackTrace);
      return [];
    }
  }

  /// Obtiene el inventario para una casa específica
  Future<List<InventoryItem>> getInventoryForHouse(int houseId) async {
    try {
      final result = await _dbService.query(
        'SELECT * FROM house_inventory WHERE house_id = @houseId ORDER BY item_id',
        {'houseId': houseId},
      );
      
      return result.map((row) => InventoryItem.fromMap(row)).toList();
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener inventario para casa $houseId', e, stackTrace);
      return [];
    }
  }

  /// Crea un nuevo elemento de inventario
  Future<InventoryItem?> createInventoryItem({
    required int houseId,
    required int itemId,
    required int quantity,
    required String status,
    required String createdBy,
  }) async {
    try {
      // Verificar si ya existe un elemento con la misma casa e item
      final existingItems = await _dbService.query(
        'SELECT * FROM house_inventory WHERE house_id = @houseId AND item_id = @itemId',
        {'houseId': houseId, 'itemId': itemId},
      );
      
      if (existingItems.isNotEmpty) {
        _logger.warning('Ya existe un elemento de inventario para la casa $houseId y el item $itemId');
        return null;
      }
      
      final result = await _dbService.query(
        '''
        INSERT INTO house_inventory (house_id, item_id, quantity)
        VALUES (@houseId, @itemId, @quantity)
        RETURNING *
        ''',
        {
          'houseId': houseId,
          'itemId': itemId,
          'quantity': quantity,
        },
      );
      
      if (result.isEmpty) {
        return null;
      }
      
      return InventoryItem.fromMap(result.first);
    } catch (e, stackTrace) {
      _logger.severe('Error al crear elemento de inventario', e, stackTrace);
      return null;
    }
  }

  /// Actualiza un elemento de inventario
  Future<bool> updateInventoryItem({
    required int id,
    int? quantity,
    String? status,
    required String updatedBy,
  }) async {
    try {
      final updates = <String, dynamic>{};
      final queryParts = <String>[];
      
      if (quantity != null) {
        updates['quantity'] = quantity;
        queryParts.add('quantity = @quantity');
      }
      
      if (queryParts.isEmpty) {
        return false;
      }
      
      updates['id'] = id;
      
      final query = '''
        UPDATE house_inventory
        SET ${queryParts.join(', ')}
        WHERE id = @id
      ''';
      
      final result = await _dbService.execute(query, updates);
      
      return result > 0;
    } catch (e, stackTrace) {
      _logger.severe('Error al actualizar elemento de inventario $id', e, stackTrace);
      return false;
    }
  }

  /// Elimina un elemento de inventario
  Future<bool> deleteInventoryItem(int id) async {
    try {
      final result = await _dbService.execute(
        'DELETE FROM house_inventory WHERE id = @id',
        {'id': id},
      );
      
      return result > 0;
    } catch (e, stackTrace) {
      _logger.severe('Error al eliminar elemento de inventario $id', e, stackTrace);
      return false;
    }
  }
  
  /// Obtiene el inventario completo para una casa en una sola consulta optimizada
  /// Utiliza la función SQL personalizada para obtener espacios, ítems y cantidades en una sola llamada
  Future<Map<String, dynamic>> getFullInventoryForHouse(int houseId) async {
    try {
      final result = await _dbService.query(
        'SELECT * FROM get_house_inventory_with_items(@houseId)',
        {'houseId': houseId},
      );
      
      // Transformar los resultados a un formato estructurado por espacios
      final Map<String, List<Map<String, dynamic>>> spaces = {};
      
      for (final row in result) {
        final spaceId = row['space_id'] as int;
        final spaceName = row['space_name'] as String;
        
        // Crear el espacio si no existe en el mapa
        if (!spaces.containsKey(spaceName)) {
          spaces[spaceName] = [];
        }
        
        // Añadir el ítem a la lista del espacio
        spaces[spaceName]!.add({
          'id': row['item_id'],
          'name': row['item_name'],
          'expected_quantity': row['expected_quantity'],
          'actual_quantity': row['actual_quantity'],
        });
      }
      
      // Calcular estadísticas de completitud por espacio
      final Map<String, Map<String, dynamic>> spaceStats = {};
      
      spaces.forEach((spaceName, items) {
        int totalItems = items.length;
        int itemsWithQuantity = items.where((item) => item['actual_quantity'] > 0).length;
        double completionPercentage = totalItems > 0 
            ? (itemsWithQuantity / totalItems) * 100 
            : 0.0;
            
        spaceStats[spaceName] = {
          'total_items': totalItems,
          'items_with_quantity': itemsWithQuantity,
          'completion_percentage': completionPercentage,
        };
      });
      
      // Calcular estadísticas globales
      int totalItems = result.length;
      int itemsWithQuantity = result.where((row) => row['actual_quantity'] > 0).length;
      double overallCompletionPercentage = totalItems > 0 
          ? (itemsWithQuantity / totalItems) * 100 
          : 0.0;
      
      // Construir la respuesta final
      return {
        'house_id': houseId,
        'spaces': spaces,
        'space_stats': spaceStats,
        'overall_stats': {
          'total_items': totalItems,
          'items_with_quantity': itemsWithQuantity,
          'completion_percentage': overallCompletionPercentage,
        }
      };
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener inventario completo para casa $houseId', e, stackTrace);
      throw e;
    }
  }
  
  /// Obtiene el resumen de inventario para una casa usando la vista materializada
  Future<Map<String, dynamic>?> getInventorySummary(int houseId) async {
    try {
      // Refrescar la vista materializada (esto podría hacerse periódicamente en lugar de cada vez)
      await _dbService.execute('SELECT refresh_inventory_summary();');
      
      // Obtener el resumen para la casa específica
      final result = await _dbService.query(
        'SELECT * FROM inventory_summary WHERE house_id = @houseId',
        {'houseId': houseId},
      );
      
      if (result.isEmpty) {
        return null;
      }
      
      // Devolver la primera fila (debería ser única por casa)
      return result.first;
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener resumen de inventario para casa $houseId', e, stackTrace);
      return null;
    }
  }
  
  /// Refresca la vista materializada de resúmenes de inventario
  Future<bool> refreshInventorySummary() async {
    try {
      await _dbService.execute('SELECT refresh_inventory_summary();');
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Error al refrescar vista materializada de inventario', e, stackTrace);
      return false;
    }
  }
} 