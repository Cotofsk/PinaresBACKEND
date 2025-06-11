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
      timeoutInSeconds: 10,
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
      
      // Ejecutar consulta simple para verificar conexión con timeout más corto
      await _connection.execute('SELECT 1')
          .timeout(const Duration(seconds: 3));
      
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
          // Si la conexión está cerrada, inicializarla de nuevo
          if (_connection.isClosed) {
            _initConnection();
          }
          await connect();
        }
        
        // Ejecutar operación con timeout
        return await operation().timeout(
          const Duration(seconds: 5), 
          onTimeout: () {
            throw TimeoutException('La operación ha tardado más de 5 segundos');
          }
        );
      } catch (e) {
        attempts++;
        
        // Si es un error de timeout, recrear la conexión
        if (e is TimeoutException) {
          _logger.warning('Timeout en la operación, recreando conexión...');
          await dispose(); // Cerrar la conexión existente
          _initConnection(); // Crear una nueva instancia
          await connect(); // Abrir la nueva conexión
        }
        
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

  /// Ejecuta una consulta SQL y devuelve los resultados
  Future<List<Map<String, dynamic>>> query(String sql, [Map<String, dynamic>? parameters]) async {
    return executeWithRetry(() async {
      final results = await _connection.mappedResultsQuery(
        sql,
        substitutionValues: parameters,
      );
      
      // Convertir resultados a formato más simple
      return results.map((row) {
        // Cada fila tiene un mapa con el nombre de la tabla como clave
        final firstTableName = row.keys.first;
        return row[firstTableName]!;
      }).toList();
    });
  }

  /// Ejecuta una operación SQL que no devuelve resultados
  Future<int> execute(String sql, [Map<String, dynamic>? parameters]) async {
    return executeWithRetry(() async {
      return await _connection.execute(
        sql,
        substitutionValues: parameters,
      );
    });
  }
} 