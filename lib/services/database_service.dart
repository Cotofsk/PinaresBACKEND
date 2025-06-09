import 'dart:async';
import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart';
import 'package:postgres/postgres.dart';

/// Servicio para manejar la conexión a la base de datos PostgreSQL
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  final _logger = Logger('DatabaseService');
  late PostgreSQLConnection _connection;
  
  // Singleton
  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal() {
    _initConnection();
  }

  /// Inicializa la conexión a la base de datos
  void _initConnection() {
    final env = DotEnv(includePlatformEnvironment: true)..load();
    
    // Obtener configuración de variables de entorno
    final host = env['DB_HOST'] ?? 'ep-patient-mud-a4aiga25-pooler.us-east-1.aws.neon.tech';
    final port = int.tryParse(env['DB_PORT'] ?? '5432') ?? 5432;
    final database = env['DB_NAME'] ?? 'neondb';
    final username = env['DB_USER'] ?? 'neondb_owner';
    final password = env['DB_PASSWORD'] ?? 'npg_Ig0qeatd5Mxk';
    
    _logger.info('Inicializando conexión a base de datos: $host:$port/$database');
    
    _connection = PostgreSQLConnection(
      host,
      port,
      database,
      username: username,
      password: password,
      useSSL: true,
      timeoutInSeconds: 60,
      timeZone: 'UTC',
      isUnixSocket: false,
      allowClearTextPassword: false,
    );
  }

  /// Abre la conexión a la base de datos
  Future<void> connect() async {
    try {
      if (_connection.isClosed) {
        _initConnection();
      }
      
      _logger.info('Conectando a la base de datos...');
      await _connection.open();
      _logger.info('Conexión a base de datos establecida');
    } catch (e) {
      _logger.severe('Error al conectar a la base de datos: $e');
      rethrow;
    }
  }

  /// Verifica si la conexión está activa
  Future<bool> isConnectionActive() async {
    try {
      if (_connection.isClosed) {
        return false;
      }
      
      // Ejecutar consulta simple para verificar conexión
      await _connection.execute('SELECT 1')
          .timeout(const Duration(seconds: 5));
      
      return true;
    } catch (e) {
      _logger.warning('La conexión no está activa: $e');
      return false;
    }
  }

  /// Ejecuta una operación con reintentos
  Future<T> executeWithRetry<T>(Future<T> Function() operation, {int maxRetries = 3}) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        // Verificar y asegurar conexión
        if (!await isConnectionActive()) {
          _logger.info('Reconectando a la base de datos...');
          await connect();
        }
        
        // Ejecutar operación
        return await operation();
      } catch (e) {
        attempts++;
        
        if (attempts >= maxRetries) {
          _logger.severe('Error después de $maxRetries intentos: $e');
          rethrow;
        }
        
        // Esperar antes de reintentar (backoff exponencial)
        final waitTime = Duration(milliseconds: 200 * (1 << attempts));
        _logger.warning('Reintento $attempts después de ${waitTime.inMilliseconds}ms: $e');
        await Future.delayed(waitTime);
      }
    }
    
    throw Exception('No se pudo completar la operación después de $maxRetries intentos');
  }

  /// Cierra la conexión a la base de datos
  Future<void> dispose() async {
    try {
      if (!_connection.isClosed) {
        _logger.info('Cerrando conexión a la base de datos');
        await _connection.close();
      }
    } catch (e) {
      _logger.warning('Error al cerrar la conexión: $e');
    }
  }
  
  // Getter para exponer la conexión a los servicios
  PostgreSQLConnection get connection => _connection;
} 