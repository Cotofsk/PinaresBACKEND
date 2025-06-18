import 'package:logging/logging.dart';

import '../models/task_model.dart';
import 'database_service.dart';
import 'websocket_service.dart';
import 'notification_service.dart';

/// Servicio para manejar operaciones de tareas
class TasksService {
  final _logger = Logger('TasksService');
  final _dbService = DatabaseService();
  final _wsService = WebSocketService();
  final _notificationService = NotificationService();

  /// Obtiene una tarea por ID
  Future<Task?> getTaskById(int taskId) async {
    try {
      // Obtener datos de la tarea
      final taskResult = await _dbService.query(
        'SELECT * FROM tareas WHERE id = @id',
        {'id': taskId},
      );
      
      if (taskResult.isEmpty) {
        _logger.warning('No se encontró la tarea con ID $taskId');
        return null;
      }
      
      // Obtener la casa asociada
      final houseResult = await _dbService.query(
        'SELECT name, type FROM houses WHERE id = @id',
        {'id': taskResult.first['id_casa']},
      );
      
      // Obtener usuarios asignados
      final usersResult = await getTaskUsers(taskId);
      
      // Registrar información de usuarios encontrados
      _logger.info('👥 Usuarios encontrados para tarea $taskId: ${usersResult.length}');
      for (final user in usersResult) {
        _logger.info('👤 - Usuario: ${user['nombre']} (ID: ${user['id']})');
      }
      
      // Extraer IDs y nombres de usuarios
      final assignedUserIds = usersResult.map<int>((user) => user['id'] as int).toList();
      final assignedUserNames = usersResult.map<String>((user) => user['nombre'] as String).toList();
      
      // Crear objeto de tarea con todos los datos
      final task = Task.fromMap({
        'id': taskResult.first['id'],
        'title': taskResult.first['tipo'],
        'description': taskResult.first['tipo'],
        'priority': 1,
        'status': taskResult.first['estado'],
        'house_id': taskResult.first['id_casa'],
        'house_name': houseResult.isNotEmpty ? houseResult.first['name'] : null,
        'house_type': houseResult.isNotEmpty ? houseResult.first['type'] : null,
        'assigned_to': usersResult.isNotEmpty ? usersResult.map((u) => u['nombre']).join(', ') : null,
        'assigned_user_ids': assignedUserIds,
        'assigned_user_names': assignedUserNames,
        'created_at': taskResult.first['fecha_creacion']?.toString(),
        'updated_at': null,
      });
      
      return task;
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener tarea por ID', e, stackTrace);
      return null;
    }
  }

  /// Obtiene todas las tareas
  Future<List<Task>> getAllTasks() async {
    try {
      // Obtener todas las tareas
      final tasksResult = await _dbService.query(
        'SELECT * FROM tareas ORDER BY fecha_creacion DESC',
      );
      
      final List<Task> tasks = [];
      
      // Para cada tarea, obtener los usuarios asignados
      for (final taskRow in tasksResult) {
        final taskId = taskRow['id'] as int;
        
        // Obtener los usuarios asignados a esta tarea
        final usersResult = await _dbService.query(
          '''
          SELECT u.id, u.nombre, u.codigo, u.rol
          FROM tareas_usuarios tu
          JOIN accesos u ON tu.id_usuario = u.id
          WHERE tu.id_tarea = @id_tarea
          ''',
          {'id_tarea': taskId},
        );
        
        // Crear lista de nombres de usuarios asignados
        final assignedUserNames = usersResult.map((u) => u['nombre'] as String).toList();
        final assignedUserIds = usersResult.map((u) => u['id'] as int).toList();
        
        // Combinar nombre de usuarios si hay varios
        final assignedTo = assignedUserNames.isNotEmpty ? assignedUserNames.join(', ') : null;
        
        // Crear objeto de tarea con usuarios asignados
        tasks.add(Task.fromMap({
          'id': taskRow['id'],
          'title': taskRow['tipo'],
          'description': taskRow['tipo'],
          'priority': 1,
          'status': taskRow['estado'],
          'house_id': taskRow['id_casa'],
          'assigned_to': assignedTo,
          'assigned_user_ids': assignedUserIds,
          'assigned_user_names': assignedUserNames,
          'due_date': taskRow['fecha_finalizacion']?.toString(),
          'created_at': taskRow['fecha_creacion']?.toString(),
          'updated_at': taskRow['fecha_creacion']?.toString(),
          'created_by': '',
          'updated_by': '',
        }));
      }
      
      return tasks;
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener tareas', e, stackTrace);
      return [];
    }
  }

  /// Obtiene las tareas completadas de la tabla tareas_completadas
  Future<List<Task>> getCompletedTasks() async {
    try {
      // Obtener todas las tareas completadas con información de la casa
      final tasksResult = await _dbService.query(
        '''
        SELECT tc.*, h.name as house_name, h.type as house_type
        FROM tareas_completadas tc
        LEFT JOIN houses h ON tc.id_casa = h.id
        ORDER BY tc.fecha_finalizacion DESC
        ''',
      );
      
      final List<Task> tasks = [];
      
      // Crear objeto de tarea para cada resultado
      for (final taskRow in tasksResult) {
        // Crear objeto de tarea
        tasks.add(Task.fromMap({
          'id': taskRow['id'],
          'title': taskRow['tipo'],
          'description': taskRow['tipo'],
          'priority': 1,
          'status': 'completada',
          'house_id': taskRow['id_casa'],
          'house_name': taskRow['house_name'],
          'house_type': taskRow['house_type'],
          'assigned_to': null, // Las tareas completadas ya no tienen usuarios asignados
          'assigned_user_ids': [],
          'assigned_user_names': [],
          'fecha_finalizacion': taskRow['fecha_finalizacion']?.toString(),
          'created_at': taskRow['fecha_creacion']?.toString(),
          'updated_at': taskRow['fecha_finalizacion']?.toString(),
          'created_by': '',
          'updated_by': '',
        }));
      }
      
      return tasks;
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener tareas completadas', e, stackTrace);
      return [];
    }
  }

  /// Crea una nueva tarea
  Future<Task?> createTask({
    required String title,
    required String description,
    required int priority,
    int? houseId,
    String? assignedTo,
    String? dueDate,
    required String createdBy,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      
      final result = await _dbService.query(
        '''
        INSERT INTO tareas (
          tipo, id_casa, estado, fecha_creacion
        )
        VALUES (
          @tipo, @id_casa, 'pendiente', @fecha_creacion
        )
        RETURNING *
        ''',
        {
          'tipo': title,
          'id_casa': houseId,
          'fecha_creacion': now,
        },
      );
      
      if (result.isEmpty) {
        return null;
      }
      
      final newTask = Task.fromMap({
        'id': result.first['id'],
        'title': result.first['tipo'],
        'description': result.first['tipo'],
        'priority': 1,
        'status': result.first['estado'],
        'house_id': result.first['id_casa'],
        'assigned_to': null,
        'due_date': result.first['fecha_finalizacion']?.toString(),
        'created_at': result.first['fecha_creacion']?.toString(),
        'updated_at': result.first['fecha_creacion']?.toString(),
        'created_by': createdBy,
        'updated_by': createdBy,
      });
      
      // Notificar a los clientes sobre la nueva tarea usando el servicio centralizado
      _notificationService.notifyTaskUpdate(
        action: 'create',
        taskData: newTask.toMap(),
        createdBy: createdBy
      );
      
      return newTask;
    } catch (e, stackTrace) {
      _logger.severe('Error al crear tarea', e, stackTrace);
      return null;
    }
  }

  /// Actualiza una tarea existente
  Future<bool> updateTask({
    required int id,
    String? title,
    String? description,
    int? priority,
    String? status,
    int? houseId,
    String? assignedTo,
    String? dueDate,
    required String updatedBy,
  }) async {
    try {
      // Si el estado es "completada", mover a tareas_completadas usando una transacción
      if (status == 'completada') {
        final now = DateTime.now().toIso8601String();
        
        // Obtener la tarea actual antes de iniciar la transacción
        final taskResult = await _dbService.query(
          'SELECT * FROM tareas WHERE id = @id',
          {'id': id},
        );
        
        if (taskResult.isEmpty) {
          _logger.warning('No se encontró la tarea $id para completar');
          return false;
        }
        
        final taskData = taskResult.first;
        
        // Usar una transacción para realizar todas las operaciones atómicamente
        return await _dbService.connection.transaction((conn) async {
          try {
            // Si la tarea es de tipo "limpiar", actualizar el estado de la casa a "clean"
            if (taskData['tipo'].toString().toLowerCase().contains('limpiar')) {
              await conn.execute(
                'UPDATE houses SET status = @status WHERE id = @house_id',
                substitutionValues: {
                  'status': 'clean',
                  'house_id': taskData['id_casa'],
                },
              );
              
              // Notificar actualización de estado de la casa
              _wsService.notifyTopic(
                WebSocketService.TOPIC_HOUSES,
                {
                  'action': 'update_status',
                  'house_id': taskData['id_casa'],
                  'status': 'clean',
                  'timestamp': now
                }
              );
            }
            
            // Insertar en tareas_completadas
            await conn.execute(
              '''
              INSERT INTO tareas_completadas (
                id, tipo, id_casa, estado, fecha_creacion, fecha_finalizacion
              )
              VALUES (
                @id, @tipo, @id_casa, @estado, @fecha_creacion, @fecha_finalizacion
              )
              ''',
              substitutionValues: {
                'id': id,
                'tipo': taskData['tipo'],
                'id_casa': taskData['id_casa'],
                'estado': taskData['estado'] ?? 'completada',
                'fecha_creacion': taskData['fecha_creacion'],
                'fecha_finalizacion': now,
              },
            );
            
            // Eliminar relaciones con usuarios
            await conn.execute(
              'DELETE FROM tareas_usuarios WHERE id_tarea = @id_tarea',
              substitutionValues: {'id_tarea': id},
            );
            
            // Eliminar de tareas
            await conn.execute(
              'DELETE FROM tareas WHERE id = @id',
              substitutionValues: {'id': id},
            );
            
            // Notificar a los clientes que la tarea ha sido completada usando el servicio centralizado
            _notificationService.notifyTaskUpdate(
              action: 'complete',
              taskId: id,
              taskType: taskData['tipo'],
              houseId: taskData['id_casa'],
              completedBy: updatedBy
            );
            
            return true;
          } catch (e) {
            _logger.severe('Error en transacción de completar tarea: $e');
            // La transacción se revertirá automáticamente
            rethrow;
          }
        });
      }
      
      // Si no es completada, actualizar los campos
      final updates = <String, dynamic>{};
      final updateFields = <String>[];
      
      if (title != null) {
        updates['tipo'] = title;
        updateFields.add('tipo = @tipo');
      }
      
      if (houseId != null) {
        updates['id_casa'] = houseId;
        updateFields.add('id_casa = @id_casa');
      }
      
      if (status != null) {
        updates['estado'] = status;
        updateFields.add('estado = @estado');
      }
      
      if (dueDate != null) {
        updates['fecha_finalizacion'] = dueDate;
        updateFields.add('fecha_finalizacion = @fecha_finalizacion');
      }
      
      if (updateFields.isEmpty) {
        return false;
      }
      
      await _dbService.execute(
        '''
        UPDATE tareas
        SET ${updateFields.join(', ')}
        WHERE id = @id
        ''',
        {...updates, 'id': id},
      );
      
      // Obtener la tarea actualizada para la notificación
      final updatedTask = await getTaskById(id);
      if (updatedTask != null) {
        // Notificar a los clientes sobre la tarea actualizada usando el servicio centralizado
        _notificationService.notifyTaskUpdate(
          action: 'update',
          taskData: updatedTask.toMap(),
          updatedBy: updatedBy
        );
      }
      
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Error al actualizar tarea', e, stackTrace);
      return false;
    }
  }

  /// Elimina una tarea
  Future<bool> deleteTask(int id) async {
    try {
      // Eliminar relaciones con usuarios
      await _dbService.execute(
        'DELETE FROM tareas_usuarios WHERE id_tarea = @id_tarea',
        {'id_tarea': id},
      );
      
      // Eliminar la tarea
      await _dbService.execute(
        'DELETE FROM tareas WHERE id = @id',
        {'id': id},
      );
      
      // Notificar a los clientes que la tarea ha sido eliminada usando el servicio centralizado
      _notificationService.notifyTaskUpdate(
        action: 'delete',
        taskId: id
      );
      
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Error al eliminar tarea', e, stackTrace);
      return false;
    }
  }

  /// Asigna una tarea a un usuario
  Future<bool> assignTask(int taskId, List<int> userIds) async {
    try {
      // Eliminar asignaciones actuales
      await _dbService.execute(
        'DELETE FROM tareas_usuarios WHERE id_tarea = @id_tarea',
        {'id_tarea': taskId},
      );
      
      // Agregar nuevas asignaciones
      for (final userId in userIds) {
        await _dbService.execute(
          '''
          INSERT INTO tareas_usuarios (id_tarea, id_usuario)
          VALUES (@id_tarea, @id_usuario)
          ''',
          {'id_tarea': taskId, 'id_usuario': userId},
        );
      }
      
      // Obtener la tarea actualizada para la notificación
      final updatedTask = await getTaskById(taskId);
      if (updatedTask != null) {
        // Notificar a los clientes sobre la asignación de tarea usando el servicio centralizado
        _notificationService.notifyTaskUpdate(
          action: 'assign',
          taskData: updatedTask.toMap(),
          assignedUserIds: userIds
        );
      }
      
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Error al asignar tarea', e, stackTrace);
      return false;
    }
  }

  /// Obtiene los usuarios asignados a una tarea
  Future<List<Map<String, dynamic>>> getTaskUsers(int taskId) async {
    try {
      // Consulta para obtener los usuarios asignados a una tarea
      final result = await _dbService.query(
        '''
        SELECT u.id, u.nombre, u.codigo, u.rol
        FROM tareas_usuarios tu
        JOIN accesos u ON tu.id_usuario = u.id
        WHERE tu.id_tarea = @id_tarea
        ''',
        {'id_tarea': taskId},
      );
      
      _logger.info('Obtenidos ${result.length} usuarios para la tarea $taskId');
      
      return result;
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener usuarios de la tarea', e, stackTrace);
      return [];
    }
  }
} 