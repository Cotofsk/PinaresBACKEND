import 'package:logging/logging.dart';
import 'dart:async';

import '../models/item_model.dart';
import 'database_service.dart';

/// Servicio para manejar operaciones de items
class ItemsService {
  final _logger = Logger('ItemsService');
  final _dbService = DatabaseService();

  /// Obtiene todos los items para un espacio específico
  Future<List<Item>> getItemsBySpaceId(int spaceId) async {
    try {
      _logger.info('Obteniendo items para espacio $spaceId');
      
      // Simplificar la consulta para que sea más rápida
      final result = await _dbService.query(
        'SELECT id, space_id, name, expected_quantity FROM items WHERE space_id = @spaceId ORDER BY name',
        {'spaceId': spaceId},
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _logger.warning('Timeout al obtener items para espacio $spaceId');
          throw TimeoutException('La consulta ha tardado más de 5 segundos');
        },
      );
      
      _logger.info('Obtenidos ${result.length} items para espacio $spaceId');
      return result.map((row) => Item.fromMap(row)).toList();
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener items para espacio $spaceId', e, stackTrace);
      
      // Si es un timeout u otro error de conexión, devolver lista vacía
      // para que la UI pueda seguir funcionando
      if (e is TimeoutException || 
          e.toString().contains('connection') || 
          e.toString().contains('timeout')) {
        return [];
      }
      
      rethrow;
    }
  }

  /// Crea un nuevo item
  Future<Item?> createItem({
    required int spaceId,
    required String name,
    required int expectedQuantity,
  }) async {
    try {
      _logger.info('Creando item para espacio $spaceId: $name');
      
      final result = await _dbService.query(
        '''
        INSERT INTO items (space_id, name, expected_quantity)
        VALUES (@spaceId, @name, @expectedQuantity)
        RETURNING id, space_id, name, expected_quantity
        ''',
        {
          'spaceId': spaceId,
          'name': name,
          'expectedQuantity': expectedQuantity,
        },
      );
      
      if (result.isEmpty) {
        return null;
      }
      
      _logger.info('Item creado con ID ${result.first['id']}');
      return Item.fromMap(result.first);
    } catch (e, stackTrace) {
      _logger.severe('Error al crear item', e, stackTrace);
      return null;
    }
  }

  /// Actualiza un item existente
  Future<Item?> updateItem({
    required int id,
    String? name,
    int? expectedQuantity,
  }) async {
    try {
      _logger.info('Actualizando item $id');
      
      final updates = <String, dynamic>{};
      final queryParts = <String>[];
      
      if (name != null) {
        updates['name'] = name;
        queryParts.add('name = @name');
      }
      
      if (expectedQuantity != null) {
        updates['expectedQuantity'] = expectedQuantity;
        queryParts.add('expected_quantity = @expectedQuantity');
      }
      
      if (queryParts.isEmpty) {
        return null;
      }
      
      updates['id'] = id;
      
      final query = '''
        UPDATE items
        SET ${queryParts.join(', ')}
        WHERE id = @id
        RETURNING id, space_id, name, expected_quantity
      ''';
      
      final result = await _dbService.query(query, updates);
      
      if (result.isEmpty) {
        return null;
      }
      
      _logger.info('Item $id actualizado correctamente');
      return Item.fromMap(result.first);
    } catch (e, stackTrace) {
      _logger.severe('Error al actualizar item $id', e, stackTrace);
      return null;
    }
  }

  /// Elimina un item
  Future<bool> deleteItem(int id) async {
    try {
      _logger.info('Eliminando item $id');
      
      final result = await _dbService.execute(
        'DELETE FROM items WHERE id = @id',
        {'id': id},
      );
      
      _logger.info('Item $id eliminado: ${result > 0}');
      return result > 0;
    } catch (e, stackTrace) {
      _logger.severe('Error al eliminar item $id', e, stackTrace);
      return false;
    }
  }
}
