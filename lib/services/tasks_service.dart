import 'package:logging/logging.dart';

import '../models/task_model.dart';
import 'database_service.dart';

/// Servicio para manejar operaciones de tareas
class TasksService {
  final _logger = Logger('TasksService');
  final _dbService = DatabaseService();

  /// Obtiene todas las tareas
  Future<List<Task>> getAllTasks() async {
    try {
      final result = await _dbService.query(
        'SELECT * FROM tasks ORDER BY priority DESC, created_at DESC',
      );
      
      return result.map((row) => Task.fromMap(row)).toList();
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener tareas', e, stackTrace);
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
        INSERT INTO tasks (
          title, description, priority, status, house_id, assigned_to, 
          due_date, created_at, updated_at, created_by, updated_by
        )
        VALUES (
          @title, @description, @priority, 'pendiente', @houseId, @assignedTo, 
          @dueDate, @createdAt, @updatedAt, @createdBy, @updatedBy
        )
        RETURNING *
        ''',
        {
          'title': title,
          'description': description,
          'priority': priority,
          'houseId': houseId,
          'assignedTo': assignedTo,
          'dueDate': dueDate,
          'createdAt': now,
          'updatedAt': now,
          'createdBy': createdBy,
          'updatedBy': createdBy,
        },
      );
      
      if (result.isEmpty) {
        return null;
      }
      
      return Task.fromMap(result.first);
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
      final updates = <String, dynamic>{};
      final queryParts = <String>[];
      
      if (title != null) {
        updates['title'] = title;
        queryParts.add('title = @title');
      }
      
      if (description != null) {
        updates['description'] = description;
        queryParts.add('description = @description');
      }
      
      if (priority != null) {
        updates['priority'] = priority;
        queryParts.add('priority = @priority');
      }
      
      if (status != null) {
        updates['status'] = status;
        queryParts.add('status = @status');
      }
      
      if (houseId != null) {
        updates['houseId'] = houseId;
        queryParts.add('house_id = @houseId');
      }
      
      if (assignedTo != null) {
        updates['assignedTo'] = assignedTo;
        queryParts.add('assigned_to = @assignedTo');
      }
      
      if (dueDate != null) {
        updates['dueDate'] = dueDate;
        queryParts.add('due_date = @dueDate');
      }
      
      if (queryParts.isEmpty) {
        return false;
      }
      
      updates['updatedAt'] = DateTime.now().toIso8601String();
      updates['updatedBy'] = updatedBy;
      updates['id'] = id;
      
      queryParts.add('updated_at = @updatedAt');
      queryParts.add('updated_by = @updatedBy');
      
      final query = '''
        UPDATE tasks
        SET ${queryParts.join(', ')}
        WHERE id = @id
      ''';
      
      final result = await _dbService.execute(query, updates);
      
      return result > 0;
    } catch (e, stackTrace) {
      _logger.severe('Error al actualizar tarea $id', e, stackTrace);
      return false;
    }
  }

  /// Elimina una tarea
  Future<bool> deleteTask(int id) async {
    try {
      final result = await _dbService.execute(
        'DELETE FROM tasks WHERE id = @id',
        {'id': id},
      );
      
      return result > 0;
    } catch (e, stackTrace) {
      _logger.severe('Error al eliminar tarea $id', e, stackTrace);
      return false;
    }
  }

  /// Asigna una tarea a un usuario
  Future<bool> assignTask({
    required int id,
    required String assignedTo,
    required String updatedBy,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      
      final result = await _dbService.execute(
        '''
        UPDATE tasks
        SET assigned_to = @assignedTo, updated_at = @updatedAt, updated_by = @updatedBy
        WHERE id = @id
        ''',
        {
          'id': id,
          'assignedTo': assignedTo,
          'updatedAt': now,
          'updatedBy': updatedBy,
        },
      );
      
      return result > 0;
    } catch (e, stackTrace) {
      _logger.severe('Error al asignar tarea $id', e, stackTrace);
      return false;
    }
  }
} 