import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

import '../services/tasks_service.dart';

/// Controlador para manejar operaciones relacionadas con tareas
class TasksController {
  final _logger = Logger('TasksController');
  final _tasksService = TasksService();

  /// Obtiene todas las tareas
  Future<Response> getAllTasks(Request request) async {
    try {
      final tasks = await _tasksService.getAllTasks();
      
      return Response.ok(
        jsonEncode({
          'tasks': tasks.map((task) => task.toMap()).toList(),
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener tareas', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al obtener tareas'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Obtiene todas las tareas completadas
  Future<Response> getCompletedTasks(Request request) async {
    try {
      final tasks = await _tasksService.getCompletedTasks();
      
      return Response.ok(
        jsonEncode({
          'tasks': tasks.map((task) => task.toMap()).toList(),
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener tareas completadas', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al obtener tareas completadas'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Crea una nueva tarea
  Future<Response> createTask(Request request) async {
    try {
      // Verificar si el usuario tiene permisos para crear tareas
      final userRole = request.context['userRole'] as String;
      
      // Solo usuarios con permiso pueden crear tareas
      if (userRole.length <= 8 || userRole[8] != '1') {
        return Response(403, 
          body: jsonEncode({'error': 'No tiene permisos para crear tareas'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Obtener el usuario del contexto
      final userName = request.context['userName'] as String;
      
      // Leer el cuerpo de la solicitud
      final String body = await request.readAsString();
      final Map<String, dynamic> data = jsonDecode(body);
      
      _logger.info('Datos recibidos para crear tarea: $data');
      
      // Crear la tarea
      final task = await _tasksService.createTask(
        title: data['tipo'] ?? data['title'] ?? '',
        description: data['tipo'] ?? data['description'] ?? '',
        priority: data['priority'] ?? 1,
        houseId: data['id_casa'] ?? data['house_id'],
        assignedTo: data['assigned_to'],
        dueDate: data['due_date'],
        createdBy: userName,
      );
      
      if (task == null || task.id == null) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Error al crear la tarea'}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      // Asignar usuarios a la tarea si se proporcionaron
      if (data.containsKey('usuarios_ids') && data['usuarios_ids'] is List) {
        final List<int> usuariosIds = List<int>.from(data['usuarios_ids']);
        
        if (usuariosIds.isNotEmpty) {
          final success = await _tasksService.assignTask(task.id!, usuariosIds);
          
          if (!success) {
            _logger.warning('Error al asignar usuarios a la tarea ${task.id}');
          }
        }
      }
      
      _logger.info('Tarea creada por $userName: ${task.title}');
      
      return Response.ok(
        jsonEncode({
          'success': true,
          'task': task.toMap(),
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al crear tarea', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al crear tarea'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Actualiza una tarea existente
  Future<Response> updateTask(Request request, String id) async {
    try {
      final taskId = int.tryParse(id);
      if (taskId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'ID de tarea inválido'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Obtener información del usuario del contexto
      final userId = request.context['userId'] as String;
      final userName = request.context['userName'] as String;
      final userRole = request.context['userRole'] as String;
      
      // Leer el cuerpo de la solicitud
      final String body = await request.readAsString();
      final Map<String, dynamic> data = jsonDecode(body);
      
      _logger.info('Datos recibidos para actualizar tarea: $data');
      
      // Verificar si se está cambiando el estado
      final newStatus = data['status'] ?? data['estado'];
      
      // Obtener la tarea actual para validar permisos
      final task = await _tasksService.getTaskById(taskId);
      if (task == null) {
        return Response.notFound(
          jsonEncode({'error': 'Tarea no encontrada'}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      // Verificar permisos según la acción que se esté realizando
      bool hasPermission = false;
      
      // Si está intentando cambiar el estado a "en_progreso" (iniciar tarea)
      if (newStatus == 'en_progreso' && task.status == 'pendiente') {
        // Verificar si el usuario tiene permiso para iniciar cualquier tarea
        final canStartAnyTask = userRole.length > 13 && userRole[13] == '1';
        
        // Verificar si el usuario está asignado a la tarea por ID
        final isAssignedById = task.assignedUserIds != null && 
                          task.assignedUserIds!.contains(int.parse(userId));
                          
        // Verificar también por nombre de usuario (para casos donde el ID no coincide)
        bool isAssignedByName = false;
        if (data.containsKey('user_name') && task.assignedUserNames != null) {
          final userName = data['user_name'] as String;
          isAssignedByName = task.assignedUserNames!.contains(userName);
          _logger.info('📋 Verificando asignación por nombre: $userName, Resultado: $isAssignedByName');
        }
        
        // Información de depuración
        _logger.info('👤 Usuario: $userName (ID: $userId)');
        _logger.info('🔑 Rol: $userRole, Permiso iniciar cualquier tarea: $canStartAnyTask');
        _logger.info('📋 IDs asignados a tarea: ${task.assignedUserIds}');
        _logger.info('📋 Nombres asignados a tarea: ${task.assignedUserNames}');
        _logger.info('✅ Usuario asignado por ID: $isAssignedById');
        _logger.info('✅ Usuario asignado por nombre: $isAssignedByName');
        
        // Puede iniciar la tarea si tiene permiso especial o está asignado (por ID o nombre)
        hasPermission = canStartAnyTask || isAssignedById || isAssignedByName;
        
        if (!hasPermission) {
          return Response(403, 
            body: jsonEncode({
              'error': 'No tiene permisos para iniciar esta tarea. Debe estar asignado a la tarea o tener permisos especiales.',
              'details': {
                'userId': userId,
                'userName': data['user_name'],
                'taskId': taskId,
                'assignedUserIds': task.assignedUserIds,
                'assignedUserNames': task.assignedUserNames,
                'canStartAnyTask': canStartAnyTask,
                'isAssignedById': isAssignedById,
                'isAssignedByName': isAssignedByName
              }
            }),
            headers: {'content-type': 'application/json'});
        }
      }
      // Si está intentando cambiar el estado a "completada"
      else if (newStatus == 'completada' && task.status == 'en_progreso') {
        // Solo usuarios con permiso especial pueden completar tareas
        final canCompleteTask = userRole.length > 14 && userRole[14] == '1';
        
        if (!canCompleteTask) {
          return Response(403, 
            body: jsonEncode({
              'error': 'Solo los supervisores pueden marcar tareas como completadas.'
            }),
            headers: {'content-type': 'application/json'});
        }
        
        hasPermission = true;
      }
      // Para otros cambios (no de estado), verificar permisos generales
      else if (newStatus == null || newStatus == task.status) {
        // Verificar si es administrador
        final isAdmin = userRole.length > 4 && userRole[4] == '1';
        
        if (!isAdmin) {
          return Response(403, 
            body: jsonEncode({
              'error': 'No tiene permisos para modificar esta tarea.'
            }),
            headers: {'content-type': 'application/json'});
        }
        
        hasPermission = true;
      }
      // Para otros cambios de estado no permitidos
      else {
        return Response(400, 
          body: jsonEncode({
            'error': 'Cambio de estado no permitido. Las tareas pendientes solo pueden pasar a en_progreso, y las tareas en_progreso solo pueden pasar a completada.'
          }),
          headers: {'content-type': 'application/json'});
      }
      
      // Si llegamos aquí, se ha validado el permiso
      
      // Actualizar la tarea
      final success = await _tasksService.updateTask(
        id: taskId,
        title: data['title'] ?? data['tipo'],
        description: data['description'] ?? data['descripcion'],
        priority: data['priority'],
        status: newStatus,
        houseId: data['house_id'] ?? data['id_casa'],
        assignedTo: data['assigned_to'],
        dueDate: data['due_date'],
        updatedBy: userName,
      );
      
      if (!success) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Error al actualizar la tarea'}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      _logger.info('Tarea $taskId actualizada por $userName');
      
      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Tarea actualizada correctamente',
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al actualizar tarea', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al actualizar tarea'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Elimina una tarea
  Future<Response> deleteTask(Request request, String id) async {
    try {
      final taskId = int.tryParse(id);
      if (taskId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'ID de tarea inválido'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Verificar si el usuario tiene permisos para eliminar tareas
      final userRole = request.context['userRole'] as String;
      final userName = request.context['userName'] as String;
      
      // Ahora se usa el permiso en posición 8 (PERM_AGREGAR_ELIMINAR_TAREAS)
      final canModifyTasks = userRole.length > 8 && userRole[8] == '1';
      
      if (!canModifyTasks) {
        _logger.warning('Usuario $userName intentó eliminar tarea $taskId sin permiso');
        return Response(403, 
          body: jsonEncode({'error': 'No tiene permisos para eliminar tareas'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Eliminar la tarea
      final success = await _tasksService.deleteTask(taskId);
      
      if (!success) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Error al eliminar la tarea'}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      _logger.info('Tarea $taskId eliminada por $userName');
      
      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Tarea eliminada correctamente',
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al eliminar tarea', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al eliminar tarea'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }

  /// Asigna una tarea a un usuario
  Future<Response> assignTask(Request request, String id) async {
    try {
      final taskId = int.tryParse(id);
      if (taskId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'ID de tarea inválido'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Verificar si el usuario tiene permisos para asignar tareas
      final userRole = request.context['userRole'] as String;
      
      // Ahora se usa el permiso en posición 8 (PERM_AGREGAR_ELIMINAR_TAREAS)
      final canModifyTasks = userRole.length > 8 && userRole[8] == '1';
      
      if (!canModifyTasks) {
        return Response(403, 
          body: jsonEncode({'error': 'No tiene permisos para asignar tareas'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Obtener el usuario del contexto
      final userName = request.context['userName'] as String;
      
      // Leer el cuerpo de la solicitud
      final String body = await request.readAsString();
      final Map<String, dynamic> data = jsonDecode(body);
      
      List<int> userIds = [];
      
      // Comprobar si recibimos un array de IDs de usuario o un solo usuario
      if (data.containsKey('user_ids') && data['user_ids'] is List) {
        userIds = List<int>.from(data['user_ids']);
      } else if (data.containsKey('user_id') && data['user_id'] is int) {
        userIds = [data['user_id']];
      } else {
        return Response(400, 
          body: jsonEncode({'error': 'Se requiere user_ids o user_id'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Asignar la tarea usando el nuevo método
      final success = await _tasksService.assignTask(taskId, userIds);
      
      if (!success) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Error al asignar la tarea'}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      _logger.info('Tarea $taskId asignada a ${userIds.length} usuarios por $userName');
      
      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Tarea asignada correctamente',
        }),
        headers: {'content-type': 'application/json'}
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al asignar tarea', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al asignar tarea'}),
        headers: {'content-type': 'application/json'}
      );
    }
  }
}
