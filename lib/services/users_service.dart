import 'package:logging/logging.dart';

import '../models/user_model.dart';
import 'database_service.dart';

/// Servicio para manejar operaciones relacionadas con usuarios
class UsersService {
  final _logger = Logger('UsersService');
  final _dbService = DatabaseService();

  /// Obtiene todos los usuarios
  Future<List<UserModel>> getAllUsers() async {
    try {
      return await _dbService.executeWithRetry(() async {
        final results = await _dbService.connection.mappedResultsQuery(
          'SELECT id, nombre, codigo, rol, areas_permitidas FROM accesos ORDER BY nombre',
        );

        return results
            .map((r) => UserModel.fromMap({
                  'id': r['accesos']!['id'] as int,
                  'nombre': r['accesos']!['nombre'] as String,
                  'rol': r['accesos']!['rol'] as String,
                  'codigo': r['accesos']!['codigo'] as String,
                  'areas_permitidas': r['accesos']!['areas_permitidas'] as String?,
                }))
            .toList();
      });
    } catch (e) {
      _logger.severe('Error al obtener los usuarios: $e');
      return [];
    }
  }

  /// Actualiza los permisos de un usuario
  Future<bool> updateUserPermissions(String codigo, String newRol) async {
    try {
      await _dbService.executeWithRetry(() async {
        await _dbService.connection.execute(
          'UPDATE accesos SET rol = @rol WHERE codigo = @codigo',
          substitutionValues: {
            'codigo': codigo,
            'rol': newRol,
          },
        );
      });
      return true;
    } catch (e) {
      _logger.severe('Error al actualizar los permisos del usuario: $e');
      return false;
    }
  }

  /// Actualiza las áreas permitidas de un usuario
  Future<bool> updateUserAreasPermitidas(String codigo, List<String> areas) async {
    try {
      final areasString = areas.join(',');
      await _dbService.executeWithRetry(() async {
        await _dbService.connection.execute(
          'UPDATE accesos SET areas_permitidas = @areas WHERE codigo = @codigo',
          substitutionValues: {
            'codigo': codigo,
            'areas': areasString,
          },
        );
      });
      return true;
    } catch (e) {
      _logger.severe('Error al actualizar las áreas permitidas del usuario: $e');
      return false;
    }
  }

  /// Crea un nuevo usuario
  Future<bool> createUser(String nombre, String codigo, String rol) async {
    try {
      await _dbService.executeWithRetry(() async {
        await _dbService.connection.execute(
          'INSERT INTO accesos (nombre, codigo, rol) VALUES (@nombre, @codigo, @rol)',
          substitutionValues: {
            'nombre': nombre,
            'codigo': codigo,
            'rol': rol,
          },
        );
      });
      return true;
    } catch (e) {
      _logger.severe('Error al crear el usuario: $e');
      return false;
    }
  }

  /// Elimina un usuario
  Future<bool> deleteUser(String codigo) async {
    try {
      await _dbService.executeWithRetry(() async {
        await _dbService.connection.execute(
          'DELETE FROM accesos WHERE codigo = @codigo',
          substitutionValues: {
            'codigo': codigo,
          },
        );
      });
      return true;
    } catch (e) {
      _logger.severe('Error al eliminar el usuario: $e');
      return false;
    }
  }
} 