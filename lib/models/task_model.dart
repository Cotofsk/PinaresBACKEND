/// Modelo para representar una tarea
class Task {
  final int? id;
  final String title;
  final String description;
  final int priority;
  final String status;
  final int? houseId;
  final String? assignedTo;
  final List<int>? assignedUserIds;
  final List<String>? assignedUserNames;
  final String? dueDate;
  final String createdAt;
  final String updatedAt;
  final String createdBy;
  final String updatedBy;

  /// Constructor
  Task({
    this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.houseId,
    this.assignedTo,
    this.assignedUserIds,
    this.assignedUserNames,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  /// Crea una instancia de Task desde un mapa
  /// Maneja tanto la estructura de la base de datos como la estructura interna
  factory Task.fromMap(Map<String, dynamic> map) {
    List<int>? userIds;
    List<String>? userNames;
    
    // Procesar listas de usuarios asignados
    if (map.containsKey('assigned_user_ids') && map['assigned_user_ids'] != null) {
      if (map['assigned_user_ids'] is List) {
        userIds = List<int>.from(map['assigned_user_ids']);
      }
    }
    
    if (map.containsKey('assigned_user_names') && map['assigned_user_names'] != null) {
      if (map['assigned_user_names'] is List) {
        userNames = List<String>.from(map['assigned_user_names']);
      }
    }
    
    return Task(
      id: map['id'],
      title: map['title'] ?? map['tipo'] ?? '',
      description: map['description'] ?? map['tipo'] ?? '',
      priority: map['priority'] ?? 1,
      status: map['status'] ?? map['estado'] ?? 'pendiente',
      houseId: map['house_id'] ?? map['id_casa'],
      assignedTo: map['assigned_to'],
      assignedUserIds: userIds,
      assignedUserNames: userNames,
      dueDate: map['due_date'] ?? (map['fecha_finalizacion'] != null ? map['fecha_finalizacion'].toString() : null),
      createdAt: map['created_at'] ?? (map['fecha_creacion'] != null ? map['fecha_creacion'].toString() : ''),
      updatedAt: map['updated_at'] ?? (map['fecha_creacion'] != null ? map['fecha_creacion'].toString() : ''),
      createdBy: map['created_by'] ?? '',
      updatedBy: map['updated_by'] ?? '',
    );
  }

  /// Convierte la instancia a un mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'house_id': houseId,
      'assigned_to': assignedTo,
      if (assignedUserIds != null) 'assigned_user_ids': assignedUserIds,
      if (assignedUserNames != null) 'assigned_user_names': assignedUserNames,
      'due_date': dueDate,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'created_by': createdBy,
      'updated_by': updatedBy,
    };
  }

  /// Crea una copia de Task con algunos campos modificados
  Task copyWith({
    int? id,
    String? title,
    String? description,
    int? priority,
    String? status,
    int? houseId,
    String? assignedTo,
    List<int>? assignedUserIds,
    List<String>? assignedUserNames,
    String? dueDate,
    String? createdAt,
    String? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      houseId: houseId ?? this.houseId,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedUserIds: assignedUserIds ?? this.assignedUserIds,
      assignedUserNames: assignedUserNames ?? this.assignedUserNames,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, priority: $priority, status: $status)';
  }
} 