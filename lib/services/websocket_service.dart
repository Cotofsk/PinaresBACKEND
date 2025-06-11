import 'dart:async';
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Clase que gestiona las conexiones WebSocket y la notificación a los clientes
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  final _logger = Logger('WebSocketService');
  
  // Singleton pattern
  factory WebSocketService() {
    return _instance;
  }
  
  WebSocketService._internal();
  
  // Map para almacenar todas las conexiones activas
  // La clave es un identificador único de la conexión
  final Map<String, WebSocketChannel> _connections = {};
  
  // Canales temáticos para los diferentes tipos de eventos
  // Estructura: Map<topic, List<connectionId>>
  final Map<String, List<String>> _topicSubscriptions = {};
  
  /// Registra una nueva conexión WebSocket
  void registerConnection(String connectionId, WebSocketChannel channel) {
    _connections[connectionId] = channel;
    _logger.info('Nueva conexión WebSocket registrada: $connectionId');
    
    // Configurar escucha para comandos desde el cliente
    channel.stream.listen(
      (message) {
        _handleClientMessage(connectionId, message);
      },
      onDone: () => _handleConnectionClosed(connectionId),
      onError: (error) {
        _logger.warning('Error en conexión WebSocket $connectionId: $error');
        _handleConnectionClosed(connectionId);
      },
    );
  }
  
  /// Maneja los mensajes recibidos desde el cliente
  void _handleClientMessage(String connectionId, dynamic message) {
    try {
      final data = jsonDecode(message);
      
      if (data['type'] == 'subscribe') {
        _handleSubscription(connectionId, data['topic']);
      } else if (data['type'] == 'unsubscribe') {
        _handleUnsubscription(connectionId, data['topic']);
      } else if (data['type'] == 'ping') {
        _sendToConnection(connectionId, {'type': 'pong', 'timestamp': DateTime.now().toIso8601String()});
      }
    } catch (e) {
      _logger.warning('Error al procesar mensaje del cliente: $e');
    }
  }
  
  /// Gestiona la suscripción a un tópico específico
  void _handleSubscription(String connectionId, String topic) {
    if (!_topicSubscriptions.containsKey(topic)) {
      _topicSubscriptions[topic] = [];
    }
    
    if (!_topicSubscriptions[topic]!.contains(connectionId)) {
      _topicSubscriptions[topic]!.add(connectionId);
      _logger.info('Cliente $connectionId suscrito al tópico: $topic');
    }
  }
  
  /// Gestiona la cancelación de suscripción a un tópico
  void _handleUnsubscription(String connectionId, String topic) {
    if (_topicSubscriptions.containsKey(topic)) {
      _topicSubscriptions[topic]!.remove(connectionId);
      _logger.info('Cliente $connectionId canceló suscripción al tópico: $topic');
    }
  }
  
  /// Maneja el cierre de una conexión
  void _handleConnectionClosed(String connectionId) {
    // Eliminar la conexión
    _connections.remove(connectionId);
    
    // Eliminar de todas las suscripciones
    for (final topic in _topicSubscriptions.keys) {
      _topicSubscriptions[topic]!.remove(connectionId);
    }
    
    _logger.info('Conexión WebSocket cerrada: $connectionId');
  }
  
  /// Envía un mensaje a una conexión específica
  void _sendToConnection(String connectionId, Map<String, dynamic> data) {
    if (_connections.containsKey(connectionId)) {
      try {
        _connections[connectionId]!.sink.add(jsonEncode(data));
      } catch (e) {
        _logger.warning('Error al enviar mensaje a conexión $connectionId: $e');
      }
    }
  }
  
  /// Envía una notificación a todos los clientes suscritos a un tópico específico
  void notifyTopic(String topic, Map<String, dynamic> data) {
    if (!_topicSubscriptions.containsKey(topic)) {
      return;
    }
    
    final payload = {
      'type': 'notification',
      'topic': topic,
      'data': data,
      'timestamp': DateTime.now().toIso8601String()
    };
    
    int sentCount = 0;
    
    for (final connectionId in _topicSubscriptions[topic]!) {
      if (_connections.containsKey(connectionId)) {
        try {
          _connections[connectionId]!.sink.add(jsonEncode(payload));
          sentCount++;
        } catch (e) {
          _logger.warning('Error al notificar a cliente $connectionId: $e');
        }
      }
    }
    
    _logger.info('Notificación enviada a $sentCount clientes para el tópico $topic');
  }
  
  /// Define constantes para los tópicos comunes
  static const String TOPIC_HOUSES = 'houses';
  static const String TOPIC_TASKS = 'tasks';
  static const String TOPIC_NOTES = 'notes';
  static const String TOPIC_INVENTORY = 'inventory';
} 