# Usa la imagen oficial de Dart
FROM dart:stable

WORKDIR /app

# Copia todo
COPY . .

# Instala dependencias
RUN dart pub get

# Compila tu app (si aplica)
RUN dart compile exe bin/server.dart -o bin/server

# Exponer el puerto (normalmente 8080)
EXPOSE 8080

# Comando de inicio
CMD ["./bin/server"]
