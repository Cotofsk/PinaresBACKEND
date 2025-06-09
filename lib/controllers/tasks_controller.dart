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

  /// Crea una nueva tarea
  Future<Response> createTask(Request request) async {
    try {
      // Verificar si el usuario tiene permisos para crear tareas
      final userRole = request.context['userRole'] as String;
      
      // Solo usuarios con permiso pueden crear tareas
      if (userRole.length <= 9 || userRole[9] != '1') {
        return Response(403, 
          body: jsonEncode({'error': 'No tiene permisos para crear tareas'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Obtener el usuario del contexto
      final userName = request.context['userName'] as String;
      
      // Leer el cuerpo de la solicitud
      final String body = await request.readAsString();
      final Map<String, dynamic> data = jsonDecode(body);
      
      // Validar datos requeridos
      if (!data.containsKey('title') || data['title'] == null ||
          !data.containsKey('description') || data['description'] == null ||
          !data.containsKey('priority') || data['priority'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Se requieren title, description y priority'}),
          headers: {'content-type': 'application/json'});
      }
      
      final String title = data['title'];
      final String description = data['description'];
      final int priority = data['priority'];
      final int? houseId = data['house_id'];
      final String? assignedTo = data['assigned_to'];
      final String? dueDate = data['due_date'];
      
      // Crear la tarea
      final task = await _tasksService.createTask(
        title: title,
        description: description,
        priority: priority,
        houseId: houseId,
        assignedTo: assignedTo,
        dueDate: dueDate,
        createdBy: userName,
      );
      
      if (task == null) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Error al crear la tarea'}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      _logger.info('Tarea creada por $userName: $title');
      
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
      
      // Verificar si el usuario tiene permisos para actualizar tareas
      final userRole = request.context['userRole'] as String;
      
      // Solo usuarios con permiso pueden actualizar tareas
      if (userRole.length <= 9 || userRole[9] != '1') {
        return Response(403, 
          body: jsonEncode({'error': 'No tiene permisos para actualizar tareas'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Obtener el usuario del contexto
      final userName = request.context['userName'] as String;
      
      // Leer el cuerpo de la solicitud
      final String body = await request.readAsString();
      final Map<String, dynamic> data = jsonDecode(body);
      
      // Actualizar la tarea
      final success = await _tasksService.updateTask(
        id: taskId,
        title: data['title'],
        description: data['description'],
        priority: data['priority'],
        status: data['status'],
        houseId: data['house_id'],
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
      
      // Solo usuarios con permiso pueden eliminar tareas
      if (userRole.length <= 9 || userRole[9] != '1') {
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
      
      _logger.info('Tarea $taskId eliminada');
      
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
      
      // Solo usuarios con permiso pueden asignar tareas
      if (userRole.length <= 9 || userRole[9] != '1') {
        return Response(403, 
          body: jsonEncode({'error': 'No tiene permisos para asignar tareas'}),
          headers: {'content-type': 'application/json'});
      }
      
      // Obtener el usuario del contexto
      final userName = request.context['userName'] as String;
      
      // Leer el cuerpo de la solicitud
      final String body = await request.readAsString();
      final Map<String, dynamic> data = jsonDecode(body);
      
      if (!data.containsKey('assigned_to') || data['assigned_to'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Se requiere assigned_to'}),
          headers: {'content-type': 'application/json'});
      }
      
      final String assignedTo = data['assigned_to'];
      
      // Asignar la tarea
      final success = await _tasksService.assignTask(
        id: taskId,
        assignedTo: assignedTo,
        updatedBy: userName,
      );
      
      if (!success) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Error al asignar la tarea'}),
          headers: {'content-type': 'application/json'}
        );
      }
      
      _logger.info('Tarea $taskId asignada a $assignedTo por $userName');
      
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
