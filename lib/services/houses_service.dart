import 'package:logging/logging.dart';

import '../models/house_model.dart';
import 'database_service.dart';

/// Servicio para manejar operaciones relacionadas con casas
class HousesService {
  final _logger = Logger('HousesService');
  final _dbService = DatabaseService();

  /// Obtiene todas las casas
  Future<List<HouseModel>> getAllHouses() async {
    try {
      return await _dbService.executeWithRetry(() async {
        final results = await _dbService.connection.mappedResultsQuery(
          'SELECT * FROM houses ORDER BY type, '
          'CASE '
          'WHEN name ~ \'^Casa [0-9]+\$\' THEN CAST(substring(name FROM \'[0-9]+\') AS INTEGER) '
          'WHEN name ~ \'^Casa [0-9]+ EXT\$\' THEN CAST(substring(name FROM \'[0-9]+\') AS INTEGER) '
          'ELSE 9999 END',
        );

        return results
            .map((r) => HouseModel.fromMap(r['houses']!))
            .toList();
      });
    } catch (e) {
      _logger.severe('Error al obtener las casas: $e');
      return [];
    }
  }

  /// Obtiene una casa por su ID
  Future<HouseModel?> getHouseById(int houseId) async {
    try {
      return await _dbService.executeWithRetry(() async {
        final results = await _dbService.connection.mappedResultsQuery(
          'SELECT * FROM houses WHERE id = @id',
          substitutionValues: {
            'id': houseId,
          },
        );

        if (results.isEmpty) {
          return null;
        }

        return HouseModel.fromMap(results.first['houses']!);
      });
    } catch (e) {
      _logger.severe('Error al obtener la casa: $e');
      return null;
    }
  }

  /// Actualiza el estado de una casa
  Future<bool> updateHouseStatus(int houseId, String status) async {
    try {
      await _dbService.executeWithRetry(() async {
        // Obtener la hora local actual
        final localTime = DateTime.now();
        // Convertir a UTC para la base de datos
        final utcTime = localTime.toUtc();

        await _dbService.connection.execute(
          'UPDATE houses SET status = @status, updated_at = @updated_at '
          'WHERE id = @id',
          substitutionValues: {
            'id': houseId,
            'status': status,
            'updated_at': utcTime,
          },
        );
      });
      return true;
    } catch (e) {
      _logger.severe('Error al actualizar el estado de la casa: $e');
      return false;
    }
  }

  /// Actualiza los checks de una casa
  Future<bool> updateHouseChecks(int houseId, String checks) async {
    try {
      await _dbService.executeWithRetry(() async {
        await _dbService.connection.execute(
          'UPDATE houses SET "Checks" = @checks '
          'WHERE id = @id',
          substitutionValues: {
            'id': houseId,
            'checks': checks,
          },
        );
      });
      return true;
    } catch (e) {
      _logger.severe('Error al actualizar los checks de la casa: $e');
      return false;
    }
  }
} 