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
  // checkInDate y checkOutDate pueden ser nulos si no hay reserva
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  // checks ahora puede ser derivado o manual. Mantendremos el campo para persistencia
  // pero la lógica de negocio debería priorizar las fechas.
  final HouseChecks checks;
  final DateTime createdAt;
  final DateTime updatedAt;

  HouseModel({
    required this.id,
    required this.name,
    required this.type,
    required this.classification,
    required this.status,
    this.checkInDate,
    this.checkOutDate,
    required this.checks,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Determina el estado de check basado en las fechas (Lógica Hotelera)
  HouseChecks get computedChecks {
    // Si no hay fechas, retornamos el estado manual guardado (compatibilidad)
    if (checkInDate == null || checkOutDate == null) {
      return checks;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Normalizar fechas de reserva a medianoche para comparación de días
    final inDate = DateTime(checkInDate!.year, checkInDate!.month, checkInDate!.day);
    final outDate = DateTime(checkOutDate!.year, checkOutDate!.month, checkOutDate!.day);

    final isArriving = today.isAtSameMomentAs(inDate);
    final isLeaving = today.isAtSameMomentAs(outDate);

    if (isArriving && isLeaving) return HouseChecks.checkInOut;
    if (isArriving) return HouseChecks.checkIn;
    if (isLeaving) return HouseChecks.checkOut;
    
    // Si hoy está dentro del rango (ocupado) pero no llega ni se va
    // podriamos retornar HouseChecks.none o un nuevo estado.
    // Por ahora retornamos none para no romper la UI existente.
    return HouseChecks.none;
  }

  /// Crea un modelo de casa a partir de un mapa
  factory HouseModel.fromMap(Map<String, dynamic> map) {
    return HouseModel(
      id: map['id'] as int,
      name: (map['name'] ?? '') as String,
      type: (map['type'] ?? '') as String,
      classification: (map['classification'] ?? '') as String,
      status: HouseStatus.fromJson((map['status'] ?? 'clean') as String),
      checkInDate: map['check_in_date'] != null 
          ? (map['check_in_date'] is DateTime ? map['check_in_date'] : DateTime.tryParse(map['check_in_date'].toString()))
          : null,
      checkOutDate: map['check_out_date'] != null
          ? (map['check_out_date'] is DateTime ? map['check_out_date'] : DateTime.tryParse(map['check_out_date'].toString()))
          : null,
      checks: HouseChecks.fromJson((map['Checks'] ?? 'Nada') as String),
      createdAt: map['created_at'] is DateTime 
          ? map['created_at'] 
          : DateTime.parse(map['created_at'].toString()),
      updatedAt: map['updated_at'] is DateTime 
          ? map['updated_at']
          : DateTime.parse(map['updated_at'].toString()),
    );
  }

  /// Convierte el modelo a un mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'classification': classification,
      'status': status.toJson(),
      'check_in_date': checkInDate?.toIso8601String(),
      'check_out_date': checkOutDate?.toIso8601String(),
      // Enviamos el valor computado al frontend para que "vea" el estado actualizado automáticamente
      // O podríamos enviar el manual. Para transición, enviamos el computado si hay fechas.
      'Checks': (checkInDate != null && checkOutDate != null) ? computedChecks.toJson() : checks.toJson(),
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