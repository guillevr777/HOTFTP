# HOTFTP

Aplicación para gestionar perfiles FTP/SFTP, explorar archivos locales y remotos, transferir y sincronizar contenido, y consultar actividad e indicadores del servicio.

## Que incluye

- Cliente multiplataforma desarrollado con Flutter y Dart.
- API REST en Node.js, Express y TypeScript.
- Persistencia PostgreSQL y autenticacion con Firebase.
- Conectividad FTP y SFTP, historial de sincronizacion y gestion de versiones.
- Despliegue de referencia para Render.

## Estructura

```text
TFG/ftp_tfg/
  backend/       API y casos de uso
  frontend/      cliente Flutter
  render.yaml    configuracion de despliegue
```

El repositorio también conserva los materiales de presentación y una compilación Android de referencia.

## Requisitos

- Node.js 20 o posterior y npm.
- Flutter y Dart compatibles con las versiones declaradas en `TFG/ftp_tfg/frontend/pubspec.yaml`.
- Una instancia PostgreSQL para ejecutar la API localmente.
- Un proyecto Firebase configurado para las plataformas que se quieran ejecutar.

## Ejecutar en local

### API

```powershell
cd TFG/ftp_tfg/backend
Copy-Item .env.example .env
npm ci
npm run dev
```

Edita `.env` con los valores de tu entorno. El ejemplo usa PostgreSQL local en el puerto `5432` y la API escucha en el puerto `3000` por defecto.

### Aplicacion Flutter

```powershell
cd TFG/ftp_tfg/frontend
flutter pub get
flutter run --dart-define=HOTFTP_API_BASE_URL=http://localhost:3000
```

Para un emulador Android, sustituye `localhost` por la dirección del equipo anfitrión accesible desde el emulador (normalmente `10.0.2.2`). Para usar la instancia desplegada, configura la URL pública de la API.

## Despliegue

La configuración de referencia de Render está en [`TFG/ftp_tfg/render.yaml`](TFG/ftp_tfg/render.yaml). Revisa los planes y las variables de entorno antes de crear recursos en tu cuenta.

## Seguridad

No guardes contraseñas, tokens ni archivos `.env` en Git. Usa `.env.example` como plantilla y configura Firebase y las cuentas de prueba con credenciales propias fuera del repositorio.
