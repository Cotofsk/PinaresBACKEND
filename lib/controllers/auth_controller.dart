import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

import '../services/database_service.dart';
import '../services/jwt_service.dart';

/// Controlador para manejar la autenticación
class AuthController {
  final _logger = Logger('AuthController');
  final _dbService = DatabaseService();
  final _jwtService = JwtService();

  /// Maneja la autenticación de usuarios
  Future<Response> login(Request request) async {
    try {
      // Leer el cuerpo de la solicitud
      final String body = await request.readAsString();
      final Map<String, dynamic> data = jsonDecode(body);
      
      // Validar que se proporcione el código
      if (!data.containsKey('codigo') || data['codigo'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Se requiere el código de acceso'}),
          headers: {'content-type': 'application/json'});
      }
      
      final String codigo = data['codigo'];
      
      // Validar el formato del código (4 dígitos)
      if (codigo.length != 4 || int.tryParse(codigo) == null) {
        return Response(400, 
          body: jsonEncode({'error': 'El código debe tener 4 dígitos numéricos'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Verificar el código en la base de datos
      final results = await _dbService.executeWithRetry(() async {
        return await _dbService.connection.mappedResultsQuery(
          'SELECT id, nombre, rol, areas_permitidas FROM accesos WHERE codigo = @codigo',
          substitutionValues: {
            'codigo': codigo,
          },
        );
      });
      
      // Si no hay resultados, el código es inválido
      if (results.isEmpty) {
        _logger.warning('Intento de acceso fallido con código: $codigo');
        return Response(401, 
          body: jsonEncode({'error': 'Código de acceso inválido'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Obtener datos del usuario
      final userData = results.first['accesos']!;
      final id = userData['id'] as int;
      final nombre = userData['nombre'] as String;
      final rol = userData['rol'] as String;
      
      // Procesar áreas permitidas
      List<String>? areasPermitidas;
      if (userData['areas_permitidas'] != null) {
        final areasStr = userData['areas_permitidas'] as String;
        if (areasStr.isNotEmpty) {
          areasPermitidas = areasStr.split(',').map((e) => e.trim()).toList();
        }
      }
      
      _logger.info('Usuario autenticado: $nombre (ID: $id)');
      
      // Generar token JWT
      final token = _jwtService.generateToken(
        codigo,
        nombre,
        rol,
        areasPermitidas,
      );
      
      // Devolver respuesta con token y datos del usuario
      return Response.ok(
        jsonEncode({
          'token': token,
          'user': {
            'id': id,
            'nombre': nombre,
            'rol': rol,
            'areas_permitidas': areasPermitidas,
          }
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error en login', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error interno del servidor'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }
} 