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

  final logger = Logger('CreateIndices');
  final dbService = DatabaseService();

  try {
    // Conectar a la base de datos
    logger.info('Conectando a la base de datos...');
    await dbService.connect();
    logger.info('Conexión establecida.');

    // Lista de índices a crear
    final indices = [
      {
        'name': 'idx_house_inventory_house_id',
        'table': 'house_inventory',
        'columns': 'house_id',
        'description': 'Índice para búsquedas de inventario por casa'
      },
      {
        'name': 'idx_house_inventory_item_id',
        'table': 'house_inventory',
        'columns': 'item_id',
        'description': 'Índice para búsquedas de inventario por ítem'
      },
      {
        'name': 'idx_house_inventory_combined',
        'table': 'house_inventory',
        'columns': 'house_id, item_id',
        'description': 'Índice combinado para búsquedas de inventario por casa e ítem'
      },
      {
        'name': 'idx_items_space_id',
        'table': 'items',
        'columns': 'space_id',
        'description': 'Índice para búsquedas de ítems por espacio'
      },
      {
        'name': 'idx_spaces_model_type',
        'table': 'spaces',
        'columns': 'model_type',
        'description': 'Índice para búsquedas de espacios por tipo de modelo'
      }
    ];

    // Crear cada índice si no existe
    for (final index in indices) {
      logger.info('Verificando índice ${index['name']}...');
      
      // Verificar si el índice ya existe
      final indexExistsResult = await dbService.query(
        '''
        SELECT EXISTS (
          SELECT 1
          FROM pg_indexes
          WHERE indexname = @indexName
        )
        ''',
        {'indexName': index['name']},
      );

      final indexExists = indexExistsResult.first['exists'] as bool;
      
      if (indexExists) {
        logger.info('El índice ${index['name']} ya existe.');
      } else {
        logger.info('Creando índice ${index['name']} en ${index['table']}...');
        
        // Crear el índice
        await dbService.execute(
          '''
          CREATE INDEX ${index['name']} ON ${index['table']}(${index['columns']});
          ''',
        );
        
        logger.info('Índice ${index['name']} creado correctamente: ${index['description']}');
      }
    }

    logger.info('Proceso de creación de índices completado.');
  } catch (e, stackTrace) {
    logger.severe('Error durante la creación de índices', e, stackTrace);
  } finally {
    // Cerrar la conexión
    await dbService.dispose();
    logger.info('Conexión cerrada.');
  }
} 