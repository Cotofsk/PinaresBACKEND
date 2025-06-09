/// Modelo para representar un elemento de inventario
class InventoryItem {
  final int? id;
  final int houseId;
  final int itemId;
  final int quantity;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String createdBy;
  final String updatedBy;

  /// Constructor
  InventoryItem({
    this.id,
    required this.houseId,
    required this.itemId,
    required this.quantity,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  /// Crea una instancia de InventoryItem desde un mapa
  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      houseId: map['house_id'],
      itemId: map['item_id'],
      quantity: map['quantity'],
      status: map['status'],
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
      'house_id': houseId,
      'item_id': itemId,
      'quantity': quantity,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'created_by': createdBy,
      'updated_by': updatedBy,
    };
  }

  /// Crea una copia de InventoryItem con algunos campos modificados
  InventoryItem copyWith({
    int? id,
    int? houseId,
    int? itemId,
    int? quantity,
    String? status,
    String? createdAt,
    String? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      houseId: houseId ?? this.houseId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  @override
  String toString() {
    return 'InventoryItem(id: $id, houseId: $houseId, itemId: $itemId, quantity: $quantity, status: $status)';
  }
} 