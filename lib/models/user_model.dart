import 'dart:convert';

/// Modelo para representar un usuario
class UserModel {
  final int? id;
  final String nombre;
  final String rol;
  final String? codigo;
  final List<String>? areasPermitidas;

  UserModel({
    this.id,
    required this.nombre,
    required this.rol,
    this.codigo,
    this.areasPermitidas,
  });

  /// Crea un modelo de usuario a partir de un mapa
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Procesar areasPermitidas si existe
    List<String>? areas;
    if (map.containsKey('areas_permitidas') && map['areas_permitidas'] != null) {
      if (map['areas_permitidas'] is List) {
        areas = List<String>.from(map['areas_permitidas']);
      } else if (map['areas_permitidas'] is String) {
        // Si es una cadena, intentar parsear como lista
        final areasString = map['areas_permitidas'] as String;
        if (areasString.isNotEmpty) {
          areas = areasString.split(',').map((e) => e.trim()).toList();
        }
      }
    }

    return UserModel(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      rol: map['rol'] as String,
      codigo: map['codigo'] as String?,
      areasPermitidas: areas,
    );
  }

  /// Convierte el modelo a un mapa
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'rol': rol,
      if (codigo != null) 'codigo': codigo,
      if (areasPermitidas != null) 'areas_permitidas': areasPermitidas!.join(','),
    };
  }

  /// Convierte el modelo a JSON
  String toJson() => jsonEncode(toMap());
  
  /// Crea un modelo de usuario a partir de JSON
  factory UserModel.fromJson(String source) => 
      UserModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  /// Verifica si el usuario tiene un permiso específico
  bool hasPermission(int permissionIndex) {
    // Si el índice está fuera del rango de la cadena, no tiene permiso
    if (permissionIndex >= rol.length) {
      return false;
    }
    
    // Verificar si el carácter en la posición indicada es '1'
    return rol[permissionIndex] == '1';
  }
  
  /// Índices de permisos
  static const int PERM_OPERACIONES = 0;
  static const int PERM_NOTAS = 1;
  static const int PERM_INVENTARIO = 2;
  static const int PERM_INFORMES = 3;
  static const int PERM_USUARIOS = 4;
  static const int PERM_CONTROL_INTERNO = 5;
  static const int PERM_BOTONES_CASAS = 6;
  static const int PERM_CONFIRMAR_ENTRADAS_SALIDAS = 7;
  static const int PERM_AGREGAR_TAREAS = 8;
  static const int PERM_ELIMINAR_CUALQUIER_NOTA = 9;
  static const int PERM_ELIMINAR_NOTAS_AREA = 10;
  static const int PERM_ADMIN_INVENTARIO = 11;
  static const int PERM_ESTADO_INVENTARIO = 12;
  
  /// Métodos específicos para cada permiso
  bool get canAccessOperaciones => hasPermission(PERM_OPERACIONES);
  bool get canAccessNotas => hasPermission(PERM_NOTAS);
  bool get canAccessInventario => hasPermission(PERM_INVENTARIO);
  bool get canAccessInformes => hasPermission(PERM_INFORMES);
  bool get canManageUsers => hasPermission(PERM_USUARIOS);
  bool get canAccessControlInterno => hasPermission(PERM_CONTROL_INTERNO);
  bool get canUseCasasButtons => hasPermission(PERM_BOTONES_CASAS);
  bool get canConfirmEntradasSalidas => hasPermission(PERM_CONFIRMAR_ENTRADAS_SALIDAS);
  bool get canAddTasks => hasPermission(PERM_AGREGAR_TAREAS);
  bool get canDeleteAnyNote => hasPermission(PERM_ELIMINAR_CUALQUIER_NOTA);
  bool get canDeleteOwnNotes => true;
  bool get canDeleteAreaNotes => hasPermission(PERM_ELIMINAR_NOTAS_AREA);
  bool get canAccessAdminInventario => hasPermission(PERM_ADMIN_INVENTARIO);
  bool get canAccessEstadoInventario => hasPermission(PERM_ESTADO_INVENTARIO);
} 