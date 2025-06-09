# Backend de Pinares

Backend API para la aplicación Pinares desarrollado con Dart y Shelf.

## Estructura del Proyecto

```
pinares_backend/
├── bin/
│   └── server.dart        # Punto de entrada del servidor
├── lib/
│   ├── controllers/       # Controladores para manejar las solicitudes HTTP
│   ├── middleware/        # Middleware para autenticación y otras funciones
│   ├── models/            # Modelos de datos
│   ├── routes/            # Configuración de rutas
│   └── services/          # Servicios para lógica de negocio y acceso a datos
└── pubspec.yaml           # Dependencias del proyecto
```

## Configuración

1. Crear un archivo `.env` en la raíz del proyecto con las siguientes variables:

```
PORT=8080
DB_HOST=tu_host_de_base_de_datos
DB_PORT=5432
DB_NAME=tu_nombre_de_base_de_datos
DB_USER=tu_usuario
DB_PASSWORD=tu_contraseña
JWT_SECRET=tu_clave_secreta_para_jwt
CORS_ORIGIN=*
```

## Desarrollo

1. Instalar dependencias:
```bash
dart pub get
```

2. Ejecutar en modo desarrollo:
```bash
dart run bin/server.dart
```

## Despliegue en Railway

1. Crear un nuevo proyecto en Railway.
2. Conectar el repositorio de GitHub.
3. Configurar las variables de entorno en Railway:
   - `DB_HOST`
   - `DB_PORT`
   - `DB_NAME`
   - `DB_USER`
   - `DB_PASSWORD`
   - `JWT_SECRET`
   - `CORS_ORIGIN`

Railway detectará automáticamente el proyecto Dart y ejecutará `dart bin/server.dart` para iniciarlo.

## API Endpoints

### Autenticación
- `POST /api/auth/login` - Iniciar sesión con código de acceso

### Casas
- `GET /api/houses` - Obtener todas las casas
- `GET /api/houses/:id` - Obtener una casa por ID
- `PUT /api/houses/:id/status` - Actualizar el estado de una casa
- `PUT /api/houses/:id/checks` - Actualizar los checks de una casa

### Notas
- `GET /api/houses/:houseId/notes` - Obtener notas para una casa
- `POST /api/houses/:houseId/notes` - Crear una nota para una casa
- `DELETE /api/notes/:id` - Eliminar una nota
- `GET /api/notes/deleted` - Obtener notas eliminadas

### Usuarios
- `GET /api/users` - Obtener todos los usuarios
- `POST /api/users` - Crear un usuario
- `PUT /api/users/:codigo/permissions` - Actualizar permisos de un usuario
- `PUT /api/users/:codigo/areas` - Actualizar áreas permitidas de un usuario
- `DELETE /api/users/:codigo` - Eliminar un usuario

### Inventario
- `GET /api/inventory` - Obtener todo el inventario
- `GET /api/houses/:houseId/inventory` - Obtener inventario para una casa
- `POST /api/inventory` - Crear un elemento de inventario
- `PUT /api/inventory/:id` - Actualizar un elemento de inventario
- `DELETE /api/inventory/:id` - Eliminar un elemento de inventario 