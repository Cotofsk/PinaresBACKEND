import 'dart:convert';
import 'dart:math';
import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart';
import 'package:jwt_auth/jwt_auth.dart';

/// Servicio para manejar la generación y verificación de tokens JWT
class JwtService {
  final _logger = Logger('JwtService');
  late final String _secretKey;
  final int _expirationHours = 24; // Tokens válidos por 24 horas

  JwtService() {
    final env = DotEnv(includePlatformEnvironment: true)..load();
    // Usar la clave secreta de las variables de entorno o generar una aleatoria
    // En producción, siempre debe usarse una clave secreta fija
    _secretKey = env['JWT_SECRET'] ?? _generateRandomKey();
    _logger.info('Servicio JWT inicializado ${env['JWT_SECRET'] != null ? 'con clave configurada' : 'con clave aleatoria'}');
  }

  /// Genera un token JWT para un usuario
  String generateToken(String userId, String userName, String userRole, List<String>? userAreas) {
    final jwt = JwtAuth(secret: _secretKey);
    
    // Calcular fecha de expiración
    final expiresAt = DateTime.now().add(Duration(hours: _expirationHours));
    
    // Crear payload
    final payload = {
      'sub': userId,
      'name': userName,
      'role': userRole,
      'areas': userAreas ?? [],
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
    };
    
    // Generar token
    return jwt.generateJwt(payload);
  }

  /// Verifica y decodifica un token JWT
  Map<String, dynamic>? verifyToken(String token) {
    try {
      final jwt = JwtAuth(secret: _secretKey);
      final payload = jwt.parseJwt(token);
      
      // Verificar expiración
      final exp = payload['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      if (now > exp) {
        _logger.warning('Token expirado');
        return null;
      }
      
      return payload;
    } catch (e) {
      _logger.warning('Error al verificar token: $e');
      return null;
    }
  }

  /// Genera una clave aleatoria para desarrollo
  /// En producción, siempre debe usarse una clave secreta fija
  String _generateRandomKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }
} 