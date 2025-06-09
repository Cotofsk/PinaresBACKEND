import 'dart:convert';

/// Enumeración para las categorías de notas
enum NoteCategory {
  grave,
  moderado,
  leve;

  String toJson() => name;
  
  static NoteCategory fromJson(String json) {
    return NoteCategory.values.firstWhere(
      (e) => e.name == json,
      orElse: () => NoteCategory.leve,
    );
  }
}

/// Enumeración para las áreas de notas
enum NoteArea {
  gasfiteria,
  electricidad,
  reposicion,
  jardineria,
  otro;

  String toJson() => name;
  
  static NoteArea fromJson(String json) {
    return NoteArea.values.firstWhere(
      (e) => e.name == json,
      orElse: () => NoteArea.otro,
    );
  }
}

/// Modelo para representar una nota
class NoteModel {
  final int? id;
  final int houseId;
  final NoteCategory category;
  final NoteArea area;
  final String content;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final String? houseName;
  final String? houseType;

  NoteModel({
    this.id,
    required this.houseId,
    required this.category,
    required this.area,
    required this.content,
    required this.createdBy,
    required this.createdAt,
    this.deletedAt,
    this.houseName,
    this.houseType,
  });

  /// Crea un modelo de nota a partir de un mapa
  factory NoteModel.fromMap(Map<String, dynamic> map) {
    // Convertir el timestamp UTC a DateTime
    DateTime utcDateTime = map['created_at'] is DateTime 
        ? map['created_at']
        : DateTime.parse(map['created_at'].toString());
    
    // Convertir UTC a hora local
    DateTime localDateTime = utcDateTime.toLocal();

    // Procesar deletedAt si existe
    DateTime? deletedAtLocal;
    if (map.containsKey('deleted_at') && map['deleted_at'] != null) {
      final deletedAtUtc = map['deleted_at'] is DateTime
          ? map['deleted_at']
          : DateTime.parse(map['deleted_at'].toString());
      deletedAtLocal = deletedAtUtc.toLocal();
    }

    return NoteModel(
      id: map['id'] as int?,
      houseId: map['house_id'] as int,
      category: NoteCategory.fromJson((map['category'] ?? 'leve') as String),
      area: NoteArea.fromJson((map['area'] ?? 'otro') as String),
      content: (map['content'] ?? '') as String,
      createdBy: (map['created_by'] ?? 'system') as String,
      createdAt: localDateTime,
      deletedAt: deletedAtLocal,
      houseName: map['house_name'] as String?,
      houseType: map['house_type'] as String?,
    );
  }

  /// Convierte el modelo a un mapa
  Map<String, dynamic> toMap() {
    final map = {
      if (id != null) 'id': id,
      'house_id': houseId,
      'category': category.toJson(),
      'area': area.toJson(),
      'content': content,
      'created_by': createdBy,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
    
    if (deletedAt != null) {
      map['deleted_at'] = deletedAt!.toUtc().toIso8601String();
    }
    
    if (houseName != null) {
      map['house_name'] = houseName;
    }
    
    if (houseType != null) {
      map['house_type'] = houseType;
    }
    
    return map;
  }

  /// Convierte el modelo a JSON
  String toJson() => jsonEncode(toMap());
  
  /// Crea un modelo de nota a partir de JSON
  factory NoteModel.fromJson(String source) => 
      NoteModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
} 