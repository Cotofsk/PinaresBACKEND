/// Modelo para representar un item
class Item {
  final int? id;
  final int spaceId;
  final String name;
  final int expectedQuantity;

  Item({
    this.id,
    required this.spaceId,
    required this.name,
    required this.expectedQuantity,
  });

  /// Crea una instancia de Item desde un mapa
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      spaceId: map['space_id'],
      name: map['name'],
      expectedQuantity: map['expected_quantity'],
    );
  }

  /// Convierte la instancia a un mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'space_id': spaceId,
      'name': name,
      'expected_quantity': expectedQuantity,
    };
  }

  /// Crea una copia de Item con algunos campos modificados
  Item copyWith({
    int? id,
    int? spaceId,
    String? name,
    int? expectedQuantity,
  }) {
    return Item(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      name: name ?? this.name,
      expectedQuantity: expectedQuantity ?? this.expectedQuantity,
    );
  }

  @override
  String toString() {
    return 'Item(id: $id, spaceId: $spaceId, name: $name, expectedQuantity: $expectedQuantity)';
  }
} 