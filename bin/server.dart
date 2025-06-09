import 'dart:io';

import 'package:args/args.dart';
import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import 'package:pinares_backend/routes/api_router.dart';
import 'package:pinares_backend/services/database_service.dart';

// Configuración del logger
final _logger = Logger('pinares_backend');

void main(List<String> args) async {
  // Configurar el logger
  _setupLogging();

  // Cargar variables de entorno
  final env = DotEnv(includePlatformEnvironment: true)..load();

  // Configurar argumentos de línea de comandos
  final parser = ArgParser()..addOption('port', abbr: 'p');
  final result = parser.parse(args);

  // Usar el puerto de la variable de entorno PORT, el argumento de línea de comandos, o 8080 por defecto
  final portStr = result['port'] ?? env['PORT'] ?? '8080';
  final port = int.tryParse(portStr);

  if (port == null) {
    _logger.severe('Puerto no válido: $portStr');
    exit(1);
  }

  // Inicializar servicio de base de datos
  final dbService = DatabaseService();
  try {
    await dbService.connect();
    _logger.info('Conexión a base de datos establecida');
  } catch (e) {
    _logger.severe('Error al conectar con la base de datos: $e');
    exit(1);
  }

  // Crear router para la API
  final router = createApiRouter();

  // Crear pipeline con middlewares
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router);

  // Iniciar servidor
  final server = await serve(handler, '0.0.0.0', port);
  _logger.info('Servidor iniciado en http://${server.address.host}:${server.port}');

  // Manejar señales de cierre
  ProcessSignal.sigint.watch().listen((_) async {
    _logger.info('Cerrando servidor...');
    await dbService.dispose();
    await server.close(force: false);
    _logger.info('Servidor cerrado');
    exit(0);
  });
}

void _setupLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.time}: ${record.level.name}: ${record.message}');
    if (record.error != null) {
      print('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      print('Stack trace: ${record.stackTrace}');
    }
  });
} 