import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';

import '../services/websocket_service.dart';
import '../services/jwt_service.dart';

/// Controlador para manejar conexiones WebSocket
class WebSocketController {
  final _logger = Logger('WebSocketController');
  final _webSocketService = WebSocketService();
  final _uuid = Uuid();
  final _jwtService = JwtService();

  /// Handler para establecer la conexión WebSocket
  /// Esta función retorna un handler que acepta la conexión WebSocket
  Handler handleWebSocket() {
    return webSocketHandler((WebSocketChannel webSocket, String? protocol) {
      final String connectionId = _uuid.v4();
      _webSocketService.registerConnection(connectionId, webSocket);
      
      // Enviar mensaje de bienvenida con el ID de conexión
      webSocket.sink.add(jsonEncode({
        'type': 'welcome',
        'connectionId': connectionId,
        'message': 'Conexión WebSocket establecida. Utiliza este ID para futuras referencias.',
        'timestamp': DateTime.now().toIso8601String()
      }));
    });
  }
  
  /// Handler para establecer una conexión WebSocket autenticada
  /// Esta función primero verifica la autenticación y luego establece la conexión
  Handler handleAuthenticatedWebSocket() {
    return (Request request) async {
      try {
        // Extraer token de la URL (query parameter)
        final params = request.url.queryParameters;
        final token = params['token'];
        
        _logger.info('Intento de conexión WebSocket autenticada');
        
        if (token == null || token.isEmpty) {
          _logger.warning('Intento de conexión WebSocket sin token');
          return Response(401, 
            body: jsonEncode({'error': 'Token de autenticación requerido'}),
            headers: {'content-type': 'application/json'});
        }
        
        // Verificar token usando JwtService
        final payload = _jwtService.verifyToken(token);
        if (payload == null) {
          _logger.warning('Intento de conexión WebSocket con token inválido');
          return Response(401, 
            body: jsonEncode({'error': 'Token inválido o expirado'}),
            headers: {'content-type': 'application/json'});
        }
        
        // Si llegamos aquí, la autenticación es exitosa
        // Extraer información del usuario del payload
        final userName = payload['name'] as String;
        final role = payload['role'] as String;
        
        _logger.info('Token válido para usuario: $userName');
        
        // Crear un handler específico para esta conexión autenticada
        final authenticatedHandler = webSocketHandler((WebSocketChannel webSocket, String? protocol) {
          final String connectionId = _uuid.v4();
          
          // Registrar la conexión
          _webSocketService.registerConnection(connectionId, webSocket);
          
          // Enviar mensaje de bienvenida con información de autenticación
          webSocket.sink.add(jsonEncode({
            'type': 'welcome',
            'connectionId': connectionId,
            'userName': userName,
            'role': role,
            'message': 'Conexión WebSocket autenticada establecida.',
            'timestamp': DateTime.now().toIso8601String()
          }));
          
          _logger.info('Conexión WebSocket autenticada establecida para $userName (ID: $connectionId)');
        });
        
        // Pasar la solicitud al handler WebSocket
        return authenticatedHandler(request);
      } catch (e, stackTrace) {
        _logger.severe('Error al establecer conexión WebSocket autenticada', e, stackTrace);
        return Response.internalServerError(
          body: jsonEncode({'error': 'Error al establecer conexión WebSocket: ${e.toString()}'}),
          headers: {'content-type': 'application/json'}
        );
      }
    };
  }
  
  /// Handler para manejar el endpoint de notificación WebSocket
  /// Este endpoint permite enviar notificaciones a todos los clientes conectados
  Future<Response> handleNotify(Request request) async {
    try {
      // Leer y decodificar el cuerpo de la solicitud
      final String body = await request.readAsString();
      final Map<String, dynamic> data = jsonDecode(body);
      
      // Verificar que los campos requeridos estén presentes
      final String? topic = data['topic'] as String?;
      final Map<String, dynamic>? payload = data['data'] as Map<String, dynamic>?;
      
      if (topic == null || payload == null) {
        _logger.warning('Solicitud de notificación WebSocket incompleta: topic=$topic, data=$payload');
        return Response(400, 
          body: jsonEncode({
            'success': false,
            'message': 'Se requieren los campos "topic" y "data"'
          }),
          headers: {'content-type': 'application/json'});
      }
      
      // Enviar la notificación a todos los clientes suscritos al tópico
      _logger.info('Enviando notificación a tópico $topic: ${jsonEncode(payload)}');
      _webSocketService.notifyTopic(topic, payload);
      
      // Responder con éxito
      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Notificación enviada correctamente',
          'topic': topic,
          'timestamp': DateTime.now().toIso8601String()
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al procesar solicitud de notificación WebSocket', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'message': 'Error al enviar notificación WebSocket',
          'error': e.toString()
        }),
        headers: {'content-type': 'application/json'}
      );
    }
  }
} 