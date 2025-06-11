import 'package:logging/logging.dart';

import '../models/space_model.dart';
import 'database_service.dart';

/// Servicio para manejar operaciones de espacios
class SpacesService {
  final _logger = Logger('SpacesService');
  final _dbService = DatabaseService();

  /// Obtiene todos los espacios
  Future<List<Space>> getAllSpaces({String? modelType}) async {
    try {
      // Verificar si la tabla existe
      final tableExists = await _checkTableExists();
      
      if (!tableExists) {
        // Si la tabla no existe, crear espacios predeterminados en memoria
        return _getDefaultSpaces();
      }
      
      // Construir la consulta
      String query = 'SELECT * FROM spaces';
      Map<String, dynamic> params = {};
      
      if (modelType != null) {
        query += ' WHERE model_type = @model_type';
        params['model_type'] = modelType;
      }
      
      query += ' ORDER BY name';
      
      // Ejecutar la consulta
      final results = await _dbService.query(query, params);
      
      // Convertir resultados a objetos Space
      return results.map((row) => Space.fromMap(row)).toList();
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener espacios', e, stackTrace);
      // En caso de error, devolver espacios predeterminados
      return _getDefaultSpaces();
    }
  }

  /// Verifica si la tabla spaces existe
  Future<bool> _checkTableExists() async {
    try {
      final result = await _dbService.query(
        '''
        SELECT EXISTS (
          SELECT FROM pg_tables
          WHERE schemaname = 'public'
          AND tablename = 'spaces'
        )
        ''',
      );
      
      return result.first['exists'] as bool;
    } catch (e) {
      _logger.warning('Error al verificar si existe la tabla spaces', e);
      return false;
    }
  }

  /// Devuelve espacios predeterminados cuando la tabla no existe
  List<Space> _getDefaultSpaces() {
    _logger.info('Generando espacios predeterminados');
    return [
      Space(
        id: 1,
        name: 'Cocina',
        modelType: 'house',
      ),
      Space(
        id: 2,
        name: 'Sala',
        modelType: 'house',
      ),
      Space(
        id: 3,
        name: 'Habitación',
        modelType: 'house',
      ),
      Space(
        id: 4,
        name: 'Baño',
        modelType: 'house',
      ),
      Space(
        id: 5,
        name: 'Exterior',
        modelType: 'house',
      ),
    ];
  }
} 