/// Modelo para representar un elemento de inventario
class InventoryItem {
  final int? id;
  final int houseId;
  final int itemId;
  final int quantity;

  /// Constructor
  InventoryItem({
    this.id,
    required this.houseId,
    required this.itemId,
    required this.quantity,
  });

  /// Crea una instancia de InventoryItem desde un mapa
  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      houseId: map['house_id'],
      itemId: map['item_id'],
      quantity: map['quantity'],
    );
  }

  /// Convierte la instancia a un mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'house_id': houseId,
      'item_id': itemId,
      'quantity': quantity,
    };
  }

  /// Crea una copia de InventoryItem con algunos campos modificados
  InventoryItem copyWith({
    int? id,
    int? houseId,
    int? itemId,
    int? quantity,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      houseId: houseId ?? this.houseId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  String toString() {
    return 'InventoryItem(id: $id, houseId: $houseId, itemId: $itemId, quantity: $quantity)';
  }
} 