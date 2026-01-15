# ===============================
# STAGE 1 — Build
# ===============================
FROM dart:stable AS build

# 🔥 Cache bust manual (Railway-friendly)
ARG CACHEBUST=1
RUN echo "Cache bust -> $CACHEBUST"

WORKDIR /app

# Copiamos pubspec primero para control de dependencias
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get

# Copiamos todo el código
COPY . .

# Asegura dependencias offline (pero después del COPY)
RUN dart pub get --offline

# 💣 Forzar recompilación del binario SIEMPRE
RUN rm -f bin/server
RUN dart compile exe bin/server.dart -o bin/server

# ===============================
# STAGE 2 — Runtime
# ===============================
FROM debian:stable-slim

WORKDIR /app

# Certificados TLS (muy importante para APIs)
RUN apt-get update \
  && apt-get install -y ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Copiamos SOLO el binario final
COPY --from=build /app/bin/server /app/server

# Railway usa la variable PORT
ENV PORT=8080
EXPOSE 8080

# Ejecutamos el server
CMD ["./server"]
