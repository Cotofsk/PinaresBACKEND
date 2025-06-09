import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

import '../services/jwt_service.dart';

/// Middleware para manejar la autenticación de las solicitudes
class AuthMiddleware {
  final _logger = Logger('AuthMiddleware');
  final _jwtService = JwtService();

  /// Envuelve un handler con autenticación JWT
  Handler authenticate(Handler innerHandler) {
    return (Request request) async {
      try {
        // Extraer token del encabezado Authorization
        final authHeader = request.headers['Authorization'];
        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          _logger.warning('Token no proporcionado o formato inválido');
          return Response.unauthorized(
            jsonEncode({'error': 'Token no proporcionado o formato inválido'}),
            headers: {'content-type': 'application/json'},
          );
        }

        final token = authHeader.substring(7); // Quitar 'Bearer '
        
        // Verificar y decodificar token
        final payload = _jwtService.verifyToken(token);
        if (payload == null) {
          _logger.warning('Token inválido o expirado');
          return Response.unauthorized(
            jsonEncode({'error': 'Token inválido o expirado'}),
            headers: {'content-type': 'application/json'},
          );
        }

        // Crear nuevo request con la información del usuario
        final newRequest = request.change(context: {
          'userId': payload['sub'],
          'userName': payload['name'],
          'userRole': payload['role'],
          'userAreas': payload['areas'],
        });

        // Continuar con el handler interno
        return await innerHandler(newRequest);
      } catch (e, stackTrace) {
        _logger.severe('Error en middleware de autenticación', e, stackTrace);
        return Response.internalServerError(
          body: jsonEncode({'error': 'Error interno del servidor'}),
          headers: {'content-type': 'application/json'},
        );
      }
    };
  }
} 