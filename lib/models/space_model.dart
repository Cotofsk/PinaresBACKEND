/// Modelo para representar un espacio
class Space {
  final int? id;
  final String modelType;
  final String name;

  Space({
    this.id,
    required this.name,
    required this.modelType,
  });

  /// Convierte un mapa a un objeto Space
  factory Space.fromMap(Map<String, dynamic> map) {
    return Space(
      id: map['id'],
      name: map['name'] ?? map['nombre'] ?? '',
      modelType: map['model_type'] ?? map['tipo_modelo'] ?? 'default',
    );
  }

  /// Convierte un objeto Space a un mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'model_type': modelType,
    };
  }
} 