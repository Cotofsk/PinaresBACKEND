/// Modelo para representar una tarea
class Task {
  final int? id;
  final String title;
  final String description;
  final int priority;
  final String status;
  final int? houseId;
  final String? assignedTo;
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
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  /// Crea una instancia de Task desde un mapa
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      priority: map['priority'],
      status: map['status'],
      houseId: map['house_id'],
      assignedTo: map['assigned_to'],
      dueDate: map['due_date'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      createdBy: map['created_by'],
      updatedBy: map['updated_by'],
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