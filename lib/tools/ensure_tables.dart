import 'package:logging/logging.dart';

import '../services/database_service.dart';

Future<void> main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
    if (record.error != null) {
      print('Error: ${record.error}');
      print('Stack trace: ${record.stackTrace}');
    }
  });

  final logger = Logger('EnsureTables');
  final dbService = DatabaseService();

  try {
    // Conectar a la base de datos
    logger.info('Conectando a la base de datos...');
    await dbService.connect();
    logger.info('Conexión establecida.');

    // Verificar si existe la tabla tareas_completadas
    final tableExistsResult = await dbService.query(
      '''
      SELECT EXISTS (
        SELECT FROM pg_tables
        WHERE schemaname = 'public'
        AND tablename = 'tareas_completadas'
      )
      ''',
    );

    final tableExists = tableExistsResult.first['exists'] as bool;
    
    if (tableExists) {
      logger.info('La tabla tareas_completadas ya existe.');
    } else {
      logger.info('La tabla tareas_completadas no existe. Creándola...');
      
      // Crear la tabla tareas_completadas
      await dbService.execute(
        '''
        CREATE TABLE tareas_completadas (
          id SERIAL PRIMARY KEY,
          tipo TEXT NOT NULL,
          id_casa INTEGER NOT NULL,
          estado TEXT NOT NULL DEFAULT 'completada',
          fecha_creacion TIMESTAMP NOT NULL,
          fecha_finalizacion TIMESTAMP NOT NULL
        );
        ''',
      );
      
      logger.info('Tabla tareas_completadas creada correctamente.');
    }

    logger.info('Proceso completado.');
  } catch (e, stackTrace) {
    logger.severe('Error durante la ejecución', e, stackTrace);
  } finally {
    // Cerrar la conexión
    await dbService.close();
    logger.info('Conexión cerrada.');
  }
} 