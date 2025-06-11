import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

import '../services/spaces_service.dart';

/// Controlador para manejar operaciones relacionadas con espacios
class SpacesController {
  final _logger = Logger('SpacesController');
  final _spacesService = SpacesService();

  /// Obtiene todos los espacios
  Future<Response> getAllSpaces(Request request) async {
    try {
      // Obtener el tipo de modelo del query string si existe
      final modelType = request.url.queryParameters['model_type'];
      
      final spaces = await _spacesService.getAllSpaces(modelType: modelType);
      
      return Response.ok(
        jsonEncode({
          'spaces': spaces.map((space) => space.toMap()).toList(),
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener espacios', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al obtener espacios'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }
} 