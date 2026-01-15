# ===============================
# STAGE 1 — Build
# ===============================
FROM dart:stable AS build

ARG CACHEBUST=1
RUN echo "Cache bust -> $CACHEBUST"

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN dart pub get

COPY . .
RUN dart pub get --offline

RUN rm -f bin/server
RUN dart compile exe bin/server.dart -o bin/server

# ===============================
# STAGE 2 — Runtime
# ===============================
FROM debian:bullseye-slim

WORKDIR /app

RUN apt-get update \
  && apt-get install -y ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Copiamos el binario A /app/server
COPY --from=build /app/bin/server /app/server

ENV PORT=8080
EXPOSE 8080

CMD ["./server"]
