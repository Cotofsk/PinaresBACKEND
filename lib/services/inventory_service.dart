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
        'SELECT * FROM inventory ORDER BY house_id, item_id',
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
        'SELECT * FROM inventory WHERE house_id = @houseId ORDER BY item_id',
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
        'SELECT * FROM inventory WHERE house_id = @houseId AND item_id = @itemId',
        {'houseId': houseId, 'itemId': itemId},
      );
      
      if (existingItems.isNotEmpty) {
        _logger.warning('Ya existe un elemento de inventario para la casa $houseId y el item $itemId');
        return null;
      }
      
      final now = DateTime.now().toIso8601String();
      
      final result = await _dbService.query(
        '''
        INSERT INTO inventory (house_id, item_id, quantity, status, created_at, updated_at, created_by, updated_by)
        VALUES (@houseId, @itemId, @quantity, @status, @createdAt, @updatedAt, @createdBy, @updatedBy)
        RETURNING *
        ''',
        {
          'houseId': houseId,
          'itemId': itemId,
          'quantity': quantity,
          'status': status,
          'createdAt': now,
          'updatedAt': now,
          'createdBy': createdBy,
          'updatedBy': createdBy,
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
      
      if (status != null) {
        updates['status'] = status;
        queryParts.add('status = @status');
      }
      
      if (queryParts.isEmpty) {
        return false;
      }
      
      updates['updatedAt'] = DateTime.now().toIso8601String();
      updates['updatedBy'] = updatedBy;
      updates['id'] = id;
      
      queryParts.add('updated_at = @updatedAt');
      queryParts.add('updated_by = @updatedBy');
      
      final query = '''
        UPDATE inventory
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
        'DELETE FROM inventory WHERE id = @id',
        {'id': id},
      );
      
      return result > 0;
    } catch (e, stackTrace) {
      _logger.severe('Error al eliminar elemento de inventario $id', e, stackTrace);
      return false;
    }
  }
} 