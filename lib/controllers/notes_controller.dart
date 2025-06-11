import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

import '../models/note_model.dart';
import '../services/notes_service.dart';

/// Controlador para manejar operaciones relacionadas con notas
class NotesController {
  final _logger = Logger('NotesController');
  final _notesService = NotesService();

  /// Obtiene todas las notas para una casa
  Future<Response> getNotesForHouse(Request request, String houseId) async {
    try {
      final houseIdInt = int.tryParse(houseId);
      if (houseIdInt == null) {
        return Response(400, 
          body: jsonEncode({'error': 'ID de casa inválido'}),
          headers: {'content-type': 'application/json'});
      }
      
      final notes = await _notesService.getNotesForHouse(houseIdInt);
      
      return Response.ok(
        jsonEncode({
          'notes': notes.map((note) => note.toMap()).toList(),
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener notas', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al obtener notas'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Obtiene notas para múltiples casas
  Future<Response> getNotesForMultipleHouses(Request request) async {
    try {
      // Leer el cuerpo de la solicitud
      final String body = await request.readAsString();
      final Map<String, dynamic> data = jsonDecode(body);
      
      // Validar datos requeridos
      if (!data.containsKey('house_ids') || data['house_ids'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Se requiere la lista de IDs de casas'}),
          headers: {'content-type': 'application/json'});
      }
      
      final List<dynamic> houseIds = data['house_ids'];
      
      // Validar que todos los IDs sean números
      final List<int> validHouseIds = [];
      for (final id in houseIds) {
        final parsedId = int.tryParse(id.toString());
        if (parsedId != null) {
          validHouseIds.add(parsedId);
        }
      }
      
      if (validHouseIds.isEmpty) {
        return Response(400, 
          body: jsonEncode({'error': 'No se proporcionaron IDs de casas válidos'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Obtener las notas para todas las casas en una sola consulta
      _logger.info('Obteniendo notas para ${validHouseIds.length} casas');
      final allNotes = await _notesService.getNotesForMultipleHouses(validHouseIds);
      _logger.info('Se obtuvieron ${allNotes.length} notas en total');
      
      // Devolver las notas en un objeto con la propiedad 'notes'
      return Response.ok(
        jsonEncode({
          'notes': allNotes.map((note) => note.toMap()).toList(),
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener notas para múltiples casas', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al obtener notas para múltiples casas'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Crea una nueva nota para una casa
  Future<Response> createNote(Request request, String houseId) async {
    try {
      _logger.info('Iniciando creación de nota para casa $houseId');
      final houseIdInt = int.tryParse(houseId);
      if (houseIdInt == null) {
        return Response(400, 
          body: jsonEncode({'error': 'ID de casa inválido'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Obtener el usuario del contexto
      final userName = request.context['userName'] as String;
      _logger.info('Usuario $userName creando nota para casa $houseId');
      
      // Leer el cuerpo de la solicitud
      final String body = await request.readAsString();
      _logger.info('Cuerpo de la solicitud: $body');
      final Map<String, dynamic> data = jsonDecode(body);
      
      // Validar datos requeridos
      if (!data.containsKey('category') || data['category'] == null ||
          !data.containsKey('area') || data['area'] == null ||
          !data.containsKey('content') || data['content'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Se requieren categoría, área y contenido'}),
          headers: {'content-type': 'application/json'});
      }
      
      final String category = data['category'];
      final String area = data['area'];
      final String content = data['content'];
      
      // Validar categoría
      if (!['grave', 'moderado', 'leve'].contains(category)) {
        return Response(400, 
          body: jsonEncode({'error': 'Categoría inválida. Debe ser grave, moderado o leve'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Validar área
      if (!['gasfiteria', 'electricidad', 'reposicion', 'jardineria', 'otro'].contains(area)) {
        return Response(400, 
          body: jsonEncode({'error': 'Área inválida. Debe ser gasfiteria, electricidad, reposicion, jardineria u otro'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Crear la nota
      _logger.info('Creando nota en la base de datos: casa=$houseIdInt, categoria=$category, area=$area');
      final note = await _notesService.createNote(
        houseId: houseIdInt,
        category: category,
        area: area,
        content: content,
        createdBy: userName,
      );
      
      if (note == null) {
        _logger.warning('No se pudo crear la nota en la base de datos');
        return Response.internalServerError(
          body: jsonEncode({'error': 'Error al crear la nota'}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      _logger.info('Nota creada exitosamente: id=${note.id} para casa $houseIdInt por $userName');
      
      // Convertir la nota a un mapa para evitar problemas de serialización
      final noteMap = note.toMap();
      _logger.info('Nota serializada: $noteMap');
      
      // Construir la respuesta
      final responseBody = jsonEncode({
        'success': true,
        'note': noteMap,
      });
      _logger.info('Enviando respuesta: $responseBody');
      
      return Response.ok(
        responseBody,
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al crear nota', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al crear nota: ${e.toString()}'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Elimina una nota
  Future<Response> deleteNote(Request request, String id) async {
    try {
      final noteId = int.tryParse(id);
      if (noteId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'ID de nota inválido'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Obtener información del usuario del contexto
      final userName = request.context['userName'] as String;
      final userRole = request.context['userRole'] as String;
      final userAreas = request.context['userAreas'] as List<dynamic>? ?? [];
      
      // Verificar permisos para eliminar la nota
      final canDeleteAny = userRole.length > 9 && userRole[9] == '1';
      final canDeleteArea = userRole.length > 10 && userRole[10] == '1';
      
      // Obtener la nota antes de eliminarla para verificar permisos
      final note = await _notesService.getNoteById(noteId);
      
      if (note == null) {
        return Response.notFound(
          jsonEncode({'error': 'Nota no encontrada'}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      // Verificar si el usuario puede eliminar la nota
      bool canDelete = false;
      
      // Si puede eliminar cualquier nota
      if (canDeleteAny) {
        canDelete = true;
      }
      // Si es el creador de la nota
      else if (note.createdBy == userName) {
        canDelete = true;
      }
      // Si puede eliminar notas de un área específica y tiene el área en la lista
      else if (canDeleteArea && userAreas.contains(note.area.name)) {
        canDelete = true;
      }
      
      if (!canDelete) {
        return Response(403, 
          body: jsonEncode({'error': 'No tiene permisos para eliminar esta nota'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Eliminar la nota
      final success = await _notesService.deleteNote(noteId);
      
      if (!success) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Error al eliminar la nota'}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      _logger.info('Nota $noteId eliminada por $userName');
      
      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Nota eliminada correctamente',
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al eliminar nota', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al eliminar nota'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Obtiene las notas eliminadas del día actual
  Future<Response> getDeletedNotes(Request request) async {
    try {
      // Verificar si el usuario tiene permisos para ver notas eliminadas
      final userRole = request.context['userRole'] as String;
      
      // Solo administradores pueden ver notas eliminadas
      if (userRole.length <= 4 || userRole[4] != '1') {
        return Response(403, 
          body: jsonEncode({'error': 'No tiene permisos para ver notas eliminadas'}),
          headers: {'content-type': 'application/json'});
      }
      
      final notes = await _notesService.getDeletedNotes();
      
      return Response.ok(
        jsonEncode({
          'notes': notes.map((note) => note.toMap()).toList(),
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener notas eliminadas', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al obtener notas eliminadas'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }
} 