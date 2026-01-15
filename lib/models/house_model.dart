import 'dart:convert';

/// Enumeración para los estados de la casa
enum HouseStatus {
  clean,
  dirty,
  occupied;

  String toJson() => name;
  
  static HouseStatus fromJson(String json) {
    return HouseStatus.values.firstWhere(
      (e) => e.name == json,
      orElse: () => HouseStatus.clean,
    );
  }
}

/// Enumeración para los checks de la casa
enum HouseChecks {
  checkIn('Llega Hoy', 'Check-in'),
  checkOut('Se Va Hoy', 'Check-out'),
  checkInOut('Llega Hoy Se Va Hoy', 'Check-in Check-out'),
  none('Nada', 'Nada');

  final String displayValue;
  final String dbValue;
  const HouseChecks(this.displayValue, this.dbValue);

  String toJson() => dbValue;
  
  static HouseChecks fromJson(String json) {
    return HouseChecks.values.firstWhere(
      (e) => e.dbValue == json,
      orElse: () => HouseChecks.none,
    );
  }
}

/// Modelo para representar una casa
class HouseModel {
  final int id;
  final String name;
  final String type;
  final String classification;
  final HouseStatus status;
  final HouseChecks checks;
  final DateTime? checkInDate;   // Nueva: fecha de check-in
  final DateTime? checkOutDate;  // Nueva: fecha de check-out
  final DateTime createdAt;
  final DateTime updatedAt;

  HouseModel({
    required this.id,
    required this.name,
    required this.type,
    required this.classification,
    required this.status,
    required this.checks,
    this.checkInDate,
    this.checkOutDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HouseModel.fromMap(Map<String, dynamic> map) {
    return HouseModel(
      id: map['id'] as int,
      name: (map['name'] ?? '') as String,
      type: (map['type'] ?? '') as String,
      classification: (map['classification'] ?? '') as String,
      status: HouseStatus.fromJson((map['status'] ?? 'clean') as String),
      checks: HouseChecks.fromJson((map['Checks'] ?? 'Nada') as String),
      checkInDate: map['check_in_date'] != null
          ? (map['check_in_date'] is DateTime
              ? map['check_in_date']
              : DateTime.parse(map['check_in_date'].toString()))
          : null,
      checkOutDate: map['check_out_date'] != null
          ? (map['check_out_date'] is DateTime
              ? map['check_out_date']
              : DateTime.parse(map['check_out_date'].toString()))
          : null,
      createdAt: map['created_at'] is DateTime 
          ? map['created_at'] 
          : DateTime.parse(map['created_at'].toString()),
      updatedAt: map['updated_at'] is DateTime 
          ? map['updated_at']
          : DateTime.parse(map['updated_at'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'classification': classification,
      'status': status.toJson(),
      'Checks': checks.toJson(),
      'check_in_date': checkInDate?.toIso8601String(),
      'check_out_date': checkOutDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convierte el modelo a JSON
  String toJson() => jsonEncode(toMap());
  
  /// Crea un modelo de casa a partir de JSON
  factory HouseModel.fromJson(String source) => 
      HouseModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
} 