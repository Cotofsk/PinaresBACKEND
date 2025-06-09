import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../controllers/auth_controller.dart';
import '../controllers/houses_controller.dart';
import '../controllers/notes_controller.dart';
import '../controllers/tasks_controller.dart';
import '../controllers/users_controller.dart';
import '../controllers/inventory_controller.dart';
import '../middleware/auth_middleware.dart';

/// Crea el router principal de la API
Router createApiRouter() {
  final router = Router();
  
  // Controladores
  final authController = AuthController();
  final housesController = HousesController();
  final notesController = NotesController();
  final tasksController = TasksController();
  final usersController = UsersController();
  final inventoryController = InventoryController();
  
  // Middleware de autenticación
  final authMiddleware = AuthMiddleware();

  // Rutas públicas (no requieren autenticación)
  router.post('/api/auth/login', authController.login);
  router.get('/api/health', _healthCheck);

  // Rutas protegidas (requieren autenticación)
  // Casas
  router.get('/api/houses', authMiddleware.authenticate(housesController.getAllHouses));
  router.get('/api/houses/<id>', authMiddleware.authenticate(housesController.getHouseById));
  router.put('/api/houses/<id>/status', authMiddleware.authenticate(housesController.updateHouseStatus));
  router.put('/api/houses/<id>/checks', authMiddleware.authenticate(housesController.updateHouseChecks));
  
  // Notas
  router.get('/api/houses/<houseId>/notes', authMiddleware.authenticate(notesController.getNotesForHouse));
  router.post('/api/houses/<houseId>/notes', authMiddleware.authenticate(notesController.createNote));
  router.delete('/api/notes/<id>', authMiddleware.authenticate(notesController.deleteNote));
  router.get('/api/notes/deleted', authMiddleware.authenticate(notesController.getDeletedNotes));
  
  // Tareas
  router.get('/api/tasks', authMiddleware.authenticate(tasksController.getAllTasks));
  router.post('/api/tasks', authMiddleware.authenticate(tasksController.createTask));
  router.put('/api/tasks/<id>', authMiddleware.authenticate(tasksController.updateTask));
  router.delete('/api/tasks/<id>', authMiddleware.authenticate(tasksController.deleteTask));
  router.post('/api/tasks/<id>/assign', authMiddleware.authenticate(tasksController.assignTask));
  
  // Usuarios
  router.get('/api/users', authMiddleware.authenticate(usersController.getAllUsers));
  router.post('/api/users', authMiddleware.authenticate(usersController.createUser));
  router.put('/api/users/<codigo>/permissions', authMiddleware.authenticate(usersController.updateUserPermissions));
  router.put('/api/users/<codigo>/areas', authMiddleware.authenticate(usersController.updateUserAreas));
  router.delete('/api/users/<codigo>', authMiddleware.authenticate(usersController.deleteUser));
  
  // Inventario
  router.get('/api/inventory', authMiddleware.authenticate(inventoryController.getAllInventory));
  router.get('/api/houses/<houseId>/inventory', authMiddleware.authenticate(inventoryController.getInventoryForHouse));
  router.post('/api/inventory', authMiddleware.authenticate(inventoryController.createInventoryItem));
  router.put('/api/inventory/<id>', authMiddleware.authenticate(inventoryController.updateInventoryItem));
  router.delete('/api/inventory/<id>', authMiddleware.authenticate(inventoryController.deleteInventoryItem));

  // Ruta para manejar 404
  router.all('/<ignored|.*>', _notFound);

  return router;
}

/// Endpoint de verificación de salud del servidor
Response _healthCheck(Request request) {
  return Response.ok('{"status": "OK", "timestamp": "${DateTime.now().toIso8601String()}"}',
      headers: {'content-type': 'application/json'});
}

/// Maneja rutas no encontradas
Response _notFound(Request request) {
  return Response.notFound('{"error": "Ruta no encontrada"}',
      headers: {'content-type': 'application/json'});
} 