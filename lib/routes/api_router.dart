import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../controllers/auth_controller.dart';
import '../controllers/houses_controller.dart';
import '../controllers/notes_controller.dart';
import '../controllers/tasks_controller.dart';
import '../controllers/users_controller.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/spaces_controller.dart';
import '../controllers/items_controller.dart';
import '../controllers/websocket_controller.dart';
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
  final spacesController = SpacesController();
  final itemsController = ItemsController();
  final websocketController = WebSocketController();
  
  // Middleware de autenticación
  final authMiddleware = AuthMiddleware();

  // Rutas públicas (no requieren autenticación)
  router.post('/api/auth/login', authController.login);
  router.get('/api/health', _healthCheck);
  
  // Ruta WebSocket pública (para pruebas)
  router.get('/ws', (Request request) => websocketController.handleWebSocket()(request));
  
  // Ruta WebSocket autenticada
  router.get('/api/ws', websocketController.handleAuthenticatedWebSocket());

  // Endpoint para enviar notificaciones WebSocket
  router.post('/api/websocket/notify', authMiddleware.authenticate(websocketController.handleNotify));

  // Rutas protegidas (requieren autenticación)
  // Casas
  router.get('/api/houses', authMiddleware.authenticate(housesController.getAllHouses));
  router.get('/api/houses/<id>', authMiddleware.authenticate((request) => 
    housesController.getHouseById(request, request.params['id']!)));
  router.put('/api/houses/<id>/status', authMiddleware.authenticate((request) => 
    housesController.updateHouseStatus(request, request.params['id']!)));
  router.put('/api/houses/<id>/checks', authMiddleware.authenticate((request) => 
    housesController.updateHouseChecks(request, request.params['id']!)));
  router.put('/api/houses/<id>/booking', authMiddleware.authenticate((request) => 
    housesController.updateHouseBooking(request, request.params['id']!)));
  
  // Notas
  router.get('/api/houses/<houseId>/notes', authMiddleware.authenticate((request) => 
    notesController.getNotesForHouse(request, request.params['houseId']!)));
  router.post('/api/houses/<houseId>/notes', authMiddleware.authenticate((request) => 
    notesController.createNote(request, request.params['houseId']!)));
  router.delete('/api/notes/<id>', authMiddleware.authenticate((request) => 
    notesController.deleteNote(request, request.params['id']!)));
  router.post('/api/notes/batch', authMiddleware.authenticate(notesController.getNotesForMultipleHouses));
  router.get('/api/notes/deleted', authMiddleware.authenticate(notesController.getDeletedNotes));
  
  // Tareas
  router.get('/api/tasks', authMiddleware.authenticate(tasksController.getAllTasks));
  router.get('/api/tasks/completed', authMiddleware.authenticate(tasksController.getCompletedTasks));
  router.post('/api/tasks', authMiddleware.authenticate(tasksController.createTask));
  router.put('/api/tasks/<id>', authMiddleware.authenticate((request) =>
    tasksController.updateTask(request, request.params['id'] ?? '')));
  router.delete('/api/tasks/<id>', authMiddleware.authenticate((request) =>
    tasksController.deleteTask(request, request.params['id'] ?? '')));
  router.post('/api/tasks/<id>/assign', authMiddleware.authenticate((request) =>
    tasksController.assignTask(request, request.params['id'] ?? '')));
  router.get('/api/tasks/<id>', authMiddleware.authenticate((request) =>
    tasksController.getTaskById(request, request.params['id'] ?? '')));
  router.get('/api/tasks/<id>/users', authMiddleware.authenticate((request) =>
    tasksController.getTaskUsers(request, request.params['id'] ?? '')));
  
  // Usuarios
  router.get('/api/users', authMiddleware.authenticate(usersController.getAllUsers));
  router.post('/api/users', authMiddleware.authenticate(usersController.createUser));
  router.put('/api/users/<codigo>/permissions', authMiddleware.authenticate((request) => 
    usersController.updateUserPermissions(request, request.params['codigo']!)));
  router.put('/api/users/<codigo>/areas', authMiddleware.authenticate((request) => 
    usersController.updateUserAreas(request, request.params['codigo']!)));
  router.delete('/api/users/<codigo>', authMiddleware.authenticate((request) => 
    usersController.deleteUser(request, request.params['codigo']!)));
  
  // Espacios (para inventario)
  router.get('/api/spaces', authMiddleware.authenticate(spacesController.getAllSpaces));
  
  // Items (para espacios)
  router.get('/api/spaces/<spaceId>/items', authMiddleware.authenticate((request) => 
    itemsController.getItemsBySpaceId(request, request.params['spaceId']!)));
  router.post('/api/spaces/<spaceId>/items', authMiddleware.authenticate((request) => 
    itemsController.createItem(request, request.params['spaceId']!)));
  router.put('/api/items/<id>', authMiddleware.authenticate((request) => 
    itemsController.updateItem(request, request.params['id']!)));
  router.delete('/api/items/<id>', authMiddleware.authenticate((request) => 
    itemsController.deleteItem(request, request.params['id']!)));
  
  // Inventario
  router.get('/api/inventory', authMiddleware.authenticate(inventoryController.getAllInventory));
  router.get('/api/houses/<houseId>/inventory', authMiddleware.authenticate((request) => 
    inventoryController.getInventoryForHouse(request, request.params['houseId']!)));
  router.post('/api/inventory', authMiddleware.authenticate(inventoryController.createInventoryItem));
  router.put('/api/houses/<houseId>/inventory/<itemId>', authMiddleware.authenticate((request) => 
    inventoryController.updateHouseInventoryItem(request, request.params['houseId']!, request.params['itemId']!)));
  router.put('/api/inventory/<id>', authMiddleware.authenticate((request) => 
    inventoryController.updateInventoryItem(request, request.params['id']!)));
  router.delete('/api/inventory/<id>', authMiddleware.authenticate((request) => 
    inventoryController.deleteInventoryItem(request, request.params['id']!)));
  router.post('/api/inventory/batch', authMiddleware.authenticate(inventoryController.getInventoryForMultipleHouses));
  router.get('/api/houses/<houseId>/inventory/completion', authMiddleware.authenticate((request) => 
    inventoryController.getCompletionPercentage(request, request.params['houseId']!)));
  router.post('/api/inventory/completion', authMiddleware.authenticate(inventoryController.getCompletionPercentageForMultipleHouses));
  
  // Nuevos endpoints optimizados para inventario
  router.get('/api/houses/<houseId>/full-inventory', authMiddleware.authenticate((request) => 
    inventoryController.getFullInventoryForHouse(request, request.params['houseId']!)));
  router.get('/api/houses/<houseId>/inventory-summary', authMiddleware.authenticate((request) => 
    inventoryController.getInventorySummary(request, request.params['houseId']!)));

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