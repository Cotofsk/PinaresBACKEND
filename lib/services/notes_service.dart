import 'package:logging/logging.dart';

import '../models/note_model.dart';
import 'database_service.dart';

/// Servicio para manejar operaciones relacionadas con notas
class NotesService {
  final _logger = Logger('NotesService');
  final _dbService = DatabaseService();

  /// Obtiene todas las notas para una casa
  Future<List<NoteModel>> getNotesForHouse(int houseId) async {
    try {
      return await _dbService.executeWithRetry(() async {
        final results = await _dbService.connection.mappedResultsQuery(
          'SELECT * FROM notes WHERE house_id = @house_id ORDER BY created_at DESC',
          substitutionValues: {
            'house_id': houseId,
          },
        );

        return results
            .map((r) => NoteModel.fromMap(r['notes']!))
            .toList();
      });
    } catch (e) {
      _logger.severe('Error al obtener las notas: $e');
      return [];
    }
  }

  /// Obtiene una nota por su ID
  Future<NoteModel?> getNoteById(int noteId) async {
    try {
      return await _dbService.executeWithRetry(() async {
        final results = await _dbService.connection.mappedResultsQuery(
          'SELECT * FROM notes WHERE id = @id',
          substitutionValues: {
            'id': noteId,
          },
        );

        if (results.isEmpty) {
          return null;
        }

        return NoteModel.fromMap(results.first['notes']!);
      });
    } catch (e) {
      _logger.severe('Error al obtener la nota: $e');
      return null;
    }
  }

  /// Crea una nueva nota
  Future<NoteModel?> createNote({
    required int houseId,
    required String category,
    required String area,
    required String content,
    required String createdBy,
  }) async {
    try {
      return await _dbService.executeWithRetry(() async {
        // Obtener la hora local actual
        final localTime = DateTime.now();
        // Convertir a UTC para la base de datos
        final utcTime = localTime.toUtc();
        
        final results = await _dbService.connection.mappedResultsQuery(
          'INSERT INTO notes (house_id, category, area, content, created_by, created_at) '
          'VALUES (@house_id, @category, @area, @content, @created_by, @created_at) '
          'RETURNING *',
          substitutionValues: {
            'house_id': houseId,
            'category': category,
            'area': area,
            'content': content,
            'created_by': createdBy,
            'created_at': utcTime,
          },
        );

        if (results.isEmpty) {
          return null;
        }
        
        return NoteModel.fromMap(results.first['notes']!);
      });
    } catch (e) {
      _logger.severe('Error al crear la nota: $e');
      return null;
    }
  }

  /// Elimina una nota
  Future<bool> deleteNote(int noteId) async {
    try {
      return await _dbService.executeWithRetry(() async {
        // Iniciamos una transacción para asegurar la integridad de los datos
        await _dbService.connection.execute('BEGIN');
        
        try {
          // 1. Obtener la nota que vamos a eliminar
          final getResults = await _dbService.connection.mappedResultsQuery(
            'SELECT * FROM notes WHERE id = @id',
            substitutionValues: {
              'id': noteId,
            },
          );
          
          if (getResults.isEmpty) {
            // Si no existe la nota, terminamos la transacción y retornamos
            await _dbService.connection.execute('COMMIT');
            return false;
          }
          
          final noteData = getResults.first['notes']!;
          
          // 2. Insertar en la tabla notes_deleted
          await _dbService.connection.execute(
            '''
            INSERT INTO notes_deleted (
              house_id, category, content, created_by, created_at, area
            ) VALUES (
              @house_id, @category, @content, @created_by, @created_at, @area
            )
            ''',
            substitutionValues: {
              'house_id': noteData['house_id'],
              'category': noteData['category'],
              'content': noteData['content'],
              'created_by': noteData['created_by'],
              'created_at': noteData['created_at'],
              'area': noteData['area'],
              // deleted_at tiene valor por defecto CURRENT_TIMESTAMP
            },
          );
          
          // 3. Eliminar de la tabla notes
          await _dbService.connection.execute(
            'DELETE FROM notes WHERE id = @id',
            substitutionValues: {
              'id': noteId,
            },
          );
          
          // Confirmar la transacción
          await _dbService.connection.execute('COMMIT');
          return true;
        } catch (e) {
          // Si hay algún error, revertimos la transacción
          await _dbService.connection.execute('ROLLBACK');
          _logger.severe('Error en la transacción de eliminación de nota: $e');
          return false;
        }
      });
    } catch (e) {
      _logger.severe('Error al eliminar la nota: $e');
      return false;
    }
  }
  
  /// Obtiene las notas eliminadas del día actual
  Future<List<NoteModel>> getDeletedNotes() async {
    try {
      return await _dbService.executeWithRetry(() async {
        // Primero, obtener todas las casas para tener un mapeo completo
        final housesResults = await _dbService.connection.mappedResultsQuery(
          'SELECT id, name, type FROM houses'
        );
        
        // Crear un mapa de ID de casa a nombre y tipo
        final Map<int, Map<String, String>> housesMap = {};
        for (final row in housesResults) {
          final houseData = row['houses']!;
          housesMap[houseData['id'] as int] = {
            'name': houseData['name'] as String,
            'type': houseData['type'] as String,
          };
        }
        
        // Obtener la fecha actual en hora local
        final now = DateTime.now().toLocal();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        
        // Convertir a UTC para la consulta
        final todayUtc = today.toUtc();
        final tomorrowUtc = tomorrow.toUtc();
        
        // Obtener las notas eliminadas del día actual
        final results = await _dbService.connection.mappedResultsQuery(
          '''
          SELECT * FROM notes_deleted 
          WHERE deleted_at >= @today AND deleted_at < @tomorrow
          ORDER BY deleted_at DESC
          ''',
          substitutionValues: {
            'today': todayUtc,
            'tomorrow': tomorrowUtc,
          }
        );

        return results.map((r) {
          final data = r['notes_deleted']!;
          final houseId = data['house_id'] as int;
          
          // Buscar la casa en el mapa
          final houseInfo = housesMap[houseId];
          final houseName = houseInfo?['name'];
          final houseType = houseInfo?['type'] ?? '';
          
          return NoteModel.fromMap({
            'id': data['id'] as int,
            'house_id': houseId,
            'category': data['category'] as String,
            'area': data['area'] as String,
            'content': data['content'] as String,
            'created_by': data['created_by'] as String,
            'created_at': data['created_at'] as DateTime,
            'deleted_at': data['deleted_at'] as DateTime,
            'house_name': houseName,
            'house_type': houseType,
          });
        }).toList();
      });
    } catch (e) {
      _logger.severe('Error al obtener las notas eliminadas: $e');
      return [];
    }
  }
} 