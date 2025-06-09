import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

import '../models/user_model.dart';
import '../services/users_service.dart';

/// Controlador para manejar operaciones relacionadas con usuarios
class UsersController {
  final _logger = Logger('UsersController');
  final _usersService = UsersService();

  /// Obtiene todos los usuarios
  Future<Response> getAllUsers(Request request) async {
    try {
      // Verificar si el usuario tiene permisos para gestionar usuarios
      final userRole = request.context['userRole'] as String;
      
      // Solo administradores pueden ver todos los usuarios
      if (userRole.length <= 4 || userRole[4] != '1') {
        return Response(403, 
          body: jsonEncode({'error': 'No tiene permisos para ver usuarios'}),
          headers: {'content-type': 'application/json'});
      }
      
      final users = await _usersService.getAllUsers();
      
      return Response.ok(
        jsonEncode({
          'users': users.map((user) => user.toMap()).toList(),
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener usuarios', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al obtener usuarios'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Crea un nuevo usuario
  Future<Response> createUser(Request request) async {
    try {
      // Verificar si el usuario tiene permisos para gestionar usuarios
      final userRole = request.context['userRole'] as String;
      
      // Solo administradores pueden crear usuarios
      if (userRole.length <= 4 || userRole[4] != '1') {
        return Response(403, 
          body: jsonEncode({'error': 'No tiene permisos para crear usuarios'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Leer el cuerpo de la solicitud
      final String body = await request.readAsString();
      final Map<String, dynamic> data = jsonDecode(body);
      
      // Validar datos requeridos
      if (!data.containsKey('nombre') || data['nombre'] == null ||
          !data.containsKey('codigo') || data['codigo'] == null ||
          !data.containsKey('rol') || data['rol'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Se requieren nombre, código y rol'}),
          headers: {'content-type': 'application/json'});
      }
      
      final String nombre = data['nombre'];
      final String codigo = data['codigo'];
      final String rol = data['rol'];
      
      // Validar formato del código (4 dígitos)
      if (codigo.length != 4 || int.tryParse(codigo) == null) {
        return Response(400, 
          body: jsonEncode({'error': 'El código debe tener 4 dígitos numéricos'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Validar formato del rol (cadena binaria)
      if (!RegExp(r'^[01]+$').hasMatch(rol)) {
        return Response(400, 
          body: jsonEncode({'error': 'El rol debe ser una cadena binaria (0s y 1s)'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Crear el usuario
      final success = await _usersService.createUser(nombre, codigo, rol);
      
      if (!success) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Error al crear el usuario'}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      _logger.info('Usuario creado: $nombre ($codigo)');
      
      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Usuario creado correctamente',
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al crear usuario', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al crear usuario'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Actualiza los permisos de un usuario
  Future<Response> updateUserPermissions(Request request, String codigo) async {
    try {
      // Verificar si el usuario tiene permisos para gestionar usuarios
      final userRole = request.context['userRole'] as String;
      
      // Solo administradores pueden actualizar permisos
      if (userRole.length <= 4 || userRole[4] != '1') {
        return Response(403, 
          body: jsonEncode({'error': 'No tiene permisos para actualizar permisos de usuarios'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Leer el cuerpo de la solicitud
      final String body = await request.readAsString();
      final Map<String, dynamic> data = jsonDecode(body);
      
      if (!data.containsKey('rol') || data['rol'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Se requiere el rol'}),
          headers: {'content-type': 'application/json'});
      }
      
      final String rol = data['rol'];
      
      // Validar formato del rol (cadena binaria)
      if (!RegExp(r'^[01]+$').hasMatch(rol)) {
        return Response(400, 
          body: jsonEncode({'error': 'El rol debe ser una cadena binaria (0s y 1s)'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Actualizar los permisos
      final success = await _usersService.updateUserPermissions(codigo, rol);
      
      if (!success) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Error al actualizar los permisos del usuario'}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      _logger.info('Permisos actualizados para usuario con código $codigo');
      
      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Permisos actualizados correctamente',
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al actualizar permisos de usuario', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al actualizar permisos de usuario'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Actualiza las áreas permitidas de un usuario
  Future<Response> updateUserAreas(Request request, String codigo) async {
    try {
      // Verificar si el usuario tiene permisos para gestionar usuarios
      final userRole = request.context['userRole'] as String;
      
      // Solo administradores pueden actualizar áreas permitidas
      if (userRole.length <= 4 || userRole[4] != '1') {
        return Response(403, 
          body: jsonEncode({'error': 'No tiene permisos para actualizar áreas permitidas de usuarios'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Leer el cuerpo de la solicitud
      final String body = await request.readAsString();
      final Map<String, dynamic> data = jsonDecode(body);
      
      if (!data.containsKey('areas') || data['areas'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Se requieren las áreas permitidas'}),
          headers: {'content-type': 'application/json'});
      }
      
      final List<dynamic> areasRaw = data['areas'];
      final List<String> areas = areasRaw.map((e) => e.toString()).toList();
      
      // Validar áreas
      for (final area in areas) {
        if (!['gasfiteria', 'electricidad', 'reposicion', 'jardineria', 'otro'].contains(area)) {
          return Response(400, 
            body: jsonEncode({'error': 'Área inválida: $area. Debe ser gasfiteria, electricidad, reposicion, jardineria u otro'}),
            headers: {'content-type': 'application/json'});
        }
      }
      
      // Actualizar las áreas permitidas
      final success = await _usersService.updateUserAreasPermitidas(codigo, areas);
      
      if (!success) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Error al actualizar las áreas permitidas del usuario'}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      _logger.info('Áreas permitidas actualizadas para usuario con código $codigo');
      
      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Áreas permitidas actualizadas correctamente',
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al actualizar áreas permitidas de usuario', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al actualizar áreas permitidas de usuario'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Elimina un usuario
  Future<Response> deleteUser(Request request, String codigo) async {
    try {
      // Verificar si el usuario tiene permisos para gestionar usuarios
      final userRole = request.context['userRole'] as String;
      
      // Solo administradores pueden eliminar usuarios
      if (userRole.length <= 4 || userRole[4] != '1') {
        return Response(403, 
          body: jsonEncode({'error': 'No tiene permisos para eliminar usuarios'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Eliminar el usuario
      final success = await _usersService.deleteUser(codigo);
      
      if (!success) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Error al eliminar el usuario'}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      _logger.info('Usuario eliminado: $codigo');
      
      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Usuario eliminado correctamente',
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al eliminar usuario', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al eliminar usuario'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }
} 