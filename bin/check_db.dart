import 'package:pinares_backend/services/database_service.dart';

void main() async {
  print('Iniciando verificación de la base de datos...');
  final dbService = DatabaseService();

  try {
    print('Conectando a la base de datos...');
    await dbService.connect();
    print('Conexión establecida.');

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
      print('✅ La tabla tareas_completadas existe.');
    } else {
      print('❌ La tabla tareas_completadas NO existe. Creando tabla...');
      
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
      
      print('✅ Tabla tareas_completadas creada correctamente.');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    await dbService.close();
    print('Conexión cerrada.');
  }
} 