import 'package:logging/logging.dart';
import '../services/database_service.dart';

// Este script añade una función optimizada para obtener datos de inventario
// La función utiliza JOINs para obtener datos de espacios, ítems e inventario en una sola consulta
Future<void> main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
    if (record.error != null) {
      print('Error: ${record.error}');
      print('Stack trace: ${record.stackTrace}');
    }
  });

  final logger = Logger('OptimizeQueries');
  final dbService = DatabaseService();

  try {
    // Conectar a la base de datos
    logger.info('Conectando a la base de datos...');
    await dbService.connect();
    logger.info('Conexión establecida.');

    // Crear función para consulta optimizada
    logger.info('Verificando función get_house_inventory_with_items...');
    
    // Verificar si la función ya existe
    final functionExistsResult = await dbService.query(
      '''
      SELECT EXISTS (
        SELECT 1
        FROM pg_proc
        WHERE proname = 'get_house_inventory_with_items'
      )
      ''',
    );

    final functionExists = functionExistsResult.first['exists'] as bool;
    
    if (functionExists) {
      logger.info('La función get_house_inventory_with_items ya existe. Actualizándola...');
      
      // Eliminar función si ya existe para actualizarla
      await dbService.execute(
        'DROP FUNCTION IF EXISTS get_house_inventory_with_items(integer);'
      );
    }
    
    logger.info('Creando función get_house_inventory_with_items...');
    
    // Crear función optimizada que devuelve todos los datos necesarios en una sola consulta
    await dbService.execute(
      '''
      CREATE OR REPLACE FUNCTION get_house_inventory_with_items(p_house_id integer)
      RETURNS TABLE (
        space_id integer,
        space_name text,
        item_id integer,
        item_name text,
        expected_quantity integer,
        actual_quantity integer
      ) 
      LANGUAGE SQL
      AS \$\$
        SELECT 
          s.id AS space_id,
          s.name AS space_name,
          i.id AS item_id,
          i.name AS item_name,
          i.expected_quantity,
          COALESCE(hi.quantity, 0) AS actual_quantity
        FROM 
          spaces s
        JOIN 
          houses h ON h.id = p_house_id
        JOIN 
          items i ON i.space_id = s.id
        LEFT JOIN 
          house_inventory hi ON hi.item_id = i.id AND hi.house_id = p_house_id
        WHERE 
          s.model_type::text = h.classification::text
        ORDER BY 
          s.name, i.name;
      \$\$;
      ''',
    );
    
    logger.info('Función get_house_inventory_with_items creada correctamente.');
    
    // Probar la función con una casa
    logger.info('Probando la función con un ID de casa de ejemplo...');
    try {
      final houseIds = await dbService.query('SELECT id FROM houses LIMIT 1');
      
      if (houseIds.isNotEmpty) {
        final houseId = houseIds.first['id'] as int;
        logger.info('Obteniendo datos para casa ID: $houseId');
        
        final results = await dbService.query(
          'SELECT * FROM get_house_inventory_with_items(@houseId)',
          {'houseId': houseId},
        );
        
        logger.info('Datos obtenidos correctamente: ${results.length} filas');
        if (results.isNotEmpty) {
          logger.info('Primera fila: ${results.first}');
        }
      } else {
        logger.warning('No se encontraron casas para probar la función');
      }
    } catch (e) {
      logger.warning('Error al probar la función: $e');
    }
    
    // Crear una vista materializada para cachear los resultados
    logger.info('Verificando vista materializada inventory_summary...');
    
    // Verificar si la vista ya existe
    final viewExistsResult = await dbService.query(
      '''
      SELECT EXISTS (
        SELECT 1
        FROM pg_matviews
        WHERE matviewname = 'inventory_summary'
      )
      ''',
    );

    final viewExists = viewExistsResult.first['exists'] as bool;
    
    if (viewExists) {
      logger.info('La vista inventory_summary ya existe. Actualizándola...');
      
      // Eliminar vista si ya existe para actualizarla
      await dbService.execute(
        'DROP MATERIALIZED VIEW IF EXISTS inventory_summary;'
      );
    }
    
    logger.info('Creando vista materializada inventory_summary...');
    
    // Crear vista materializada para cachear resúmenes de inventario
    await dbService.execute(
      '''
      CREATE MATERIALIZED VIEW inventory_summary AS
      SELECT 
        h.id AS house_id,
        h.name AS house_name,
        h.classification,
        COUNT(DISTINCT i.id) AS total_items,
        SUM(CASE WHEN COALESCE(hi.quantity, 0) > 0 THEN 1 ELSE 0 END) AS items_with_quantity,
        CASE 
          WHEN COUNT(DISTINCT i.id) > 0 
          THEN ROUND((SUM(CASE WHEN COALESCE(hi.quantity, 0) > 0 THEN 1 ELSE 0 END)::numeric / COUNT(DISTINCT i.id)::numeric) * 100, 2)
          ELSE 0
        END AS completion_percentage
      FROM 
        houses h
      JOIN 
        spaces s ON s.model_type::text = h.classification::text
      JOIN 
        items i ON i.space_id = s.id
      LEFT JOIN 
        house_inventory hi ON hi.item_id = i.id AND hi.house_id = h.id
      GROUP BY 
        h.id, h.name, h.classification
      ORDER BY 
        h.id;
      ''',
    );
    
    logger.info('Vista materializada inventory_summary creada correctamente.');
    
    // Crear función para refrescar la vista materializada
    logger.info('Creando función refresh_inventory_summary...');
    
    await dbService.execute(
      '''
      CREATE OR REPLACE FUNCTION refresh_inventory_summary()
      RETURNS void
      LANGUAGE plpgsql
      AS \$\$
      BEGIN
        REFRESH MATERIALIZED VIEW inventory_summary;
      END;
      \$\$;
      ''',
    );
    
    logger.info('Función refresh_inventory_summary creada correctamente.');
    
    // Refrescar la vista materializada
    logger.info('Refrescando vista materializada inventory_summary...');
    await dbService.execute('SELECT refresh_inventory_summary();');
    logger.info('Vista materializada refrescada correctamente.');

    logger.info('Proceso de optimización de consultas completado.');
  } catch (e, stackTrace) {
    logger.severe('Error durante la optimización de consultas', e, stackTrace);
  } finally {
    // Cerrar la conexión
    await dbService.dispose();
    logger.info('Conexión cerrada.');
  }
} 