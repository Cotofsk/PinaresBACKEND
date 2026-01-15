FROM dart:stable AS build

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias
COPY pubspec.* ./
RUN dart pub get

# Copiar el resto del código
COPY . .

# Obtener dependencias
RUN dart pub get --offline

# Compilar para producción
RUN dart compile exe bin/server.dart -o bin/server

# Imagen de producción
FROM debian:bullseye-slim

# Instalar dependencias de SSL
RUN apt-get update && \
    apt-get install -y ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Establecer directorio de trabajo
WORKDIR /app

# Copiar el ejecutable compilado
COPY --from=build /app/bin/server /app/bin/server

# Exponer puerto
EXPOSE 8080

# Comando para iniciar el servidor
CMD ["/app/bin/server"] 
