import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

import '../models/house_model.dart';
import '../services/houses_service.dart';

/// Controlador para manejar operaciones relacionadas con casas
class HousesController {
  final _logger = Logger('HousesController');
  final _housesService = HousesService();

  /// Obtiene todas las casas
  Future<Response> getAllHouses(Request request) async {
    try {
      final houses = await _housesService.getAllHouses();
      
      return Response.ok(
        jsonEncode({
          'houses': houses.map((house) => house.toMap()).toList(),
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener casas', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al obtener casas'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Obtiene una casa por su ID
  Future<Response> getHouseById(Request request, String id) async {
    try {
      final houseId = int.tryParse(id);
      if (houseId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'ID de casa inválido'}),
          headers: {'content-type': 'application/json'});
      }
      
      final house = await _housesService.getHouseById(houseId);
      
      if (house == null) {
        return Response.notFound(
          jsonEncode({'error': 'Casa no encontrada'}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      return Response.ok(
        jsonEncode({
          'house': house.toMap(),
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener casa por ID', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al obtener casa'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Actualiza el estado de una casa
  Future<Response> updateHouseStatus(Request request, String id) async {
    try {
      final houseId = int.tryParse(id);
      if (houseId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'ID de casa inválido'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Obtener el usuario del contexto
      final userName = request.context['userName'] as String;
      
      // Leer el cuerpo de la solicitud
      final String body = await request.readAsString();
      final Map<String, dynamic> data = jsonDecode(body);
      
      if (!data.containsKey('status') || data['status'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Se requiere el estado'}),
          headers: {'content-type': 'application/json'});
      }
      
      final String status = data['status'];
      
      // Validar el estado
      if (!['clean', 'dirty', 'occupied'].contains(status)) {
        return Response(400, 
          body: jsonEncode({'error': 'Estado inválido. Debe ser clean, dirty u occupied'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Actualizar el estado
      final success = await _housesService.updateHouseStatus(houseId, status);
      
      if (!success) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Error al actualizar el estado de la casa'}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      _logger.info('Casa $houseId actualizada a estado $status por $userName');
      
      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Estado actualizado correctamente',
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al actualizar estado de casa', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al actualizar estado de casa'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Actualiza los checks de una casa
  Future<Response> updateHouseChecks(Request request, String id) async {
    try {
      final houseId = int.tryParse(id);
      if (houseId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'ID de casa inválido'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Obtener el usuario del contexto
      final userName = request.context['userName'] as String;
      
      // Leer el cuerpo de la solicitud
      final String body = await request.readAsString();
      final Map<String, dynamic> data = jsonDecode(body);
      
      if (!data.containsKey('checks') || data['checks'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Se requieren los checks'}),
          headers: {'content-type': 'application/json'});
      }
      
      final String checks = data['checks'];
      
      // Validar los checks
      if (!['Check-in', 'Check-out', 'Check-in Check-out', 'Nada'].contains(checks)) {
        return Response(400, 
          body: jsonEncode({'error': 'Checks inválidos. Debe ser Check-in, Check-out, Check-in Check-out o Nada'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Actualizar los checks
      final success = await _housesService.updateHouseChecks(houseId, checks);
      
      if (!success) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Error al actualizar los checks de la casa'}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      _logger.info('Casa $houseId actualizada a checks $checks por $userName');
      
      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Checks actualizados correctamente',
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al actualizar checks de casa', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al actualizar checks de casa'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Actualiza las fechas de check-in/check-out de una casa
  Future<Response> updateHouseDates(Request request, String id) async {
    try {
      final houseId = int.tryParse(id);
      if (houseId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'ID de casa inválido'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Obtener el usuario del contexto
      final userName = request.context['userName'] as String;
      
      // Leer el cuerpo de la solicitud
      final String body = await request.readAsString();
      final Map<String, dynamic> data = jsonDecode(body);
      
      // Parsear fechas (pueden ser null)
      DateTime? checkInDate;
      DateTime? checkOutDate;
      
      if (data.containsKey('check_in_date') && data['check_in_date'] != null) {
        checkInDate = DateTime.parse(data['check_in_date']);
      }
      
      if (data.containsKey('check_out_date') && data['check_out_date'] != null) {
        checkOutDate = DateTime.parse(data['check_out_date']);
      }
      
      // Actualizar las fechas
      final success = await _housesService.updateHouseDates(houseId, checkInDate, checkOutDate);
      
      if (!success) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Error al actualizar las fechas de la casa'}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      _logger.info('Casa $houseId fechas actualizadas por $userName');
      
      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Fechas actualizadas correctamente',
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al actualizar fechas de casa', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al actualizar fechas de casa'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }
}