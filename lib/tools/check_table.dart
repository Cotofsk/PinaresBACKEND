import '../services/database_service.dart';

Future<void> main() async {
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
      print('❌ La tabla tareas_completadas NO existe.');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    await dbService.close();
    print('Conexión cerrada.');
  }
} 