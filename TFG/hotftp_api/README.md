# HOTFTP API

Backend independiente de HOTFTP con Node.js, TypeScript y una estructura inspirada en Clean Architecture.

## Objetivo

La app Flutter deja de hablar con FTP directamente y pasa a consumir esta API por HTTP.

## Capas

- `src/domain`
  - entidades
  - contratos de repositorios
- `src/application`
  - casos de uso
- `src/infrastructure`
  - HTTP
  - persistencia
  - adaptadores FTP
- `src/config`
  - configuracion y wiring

## Scripts

```bash
npm install
npm run dev
```

## Arranque local

```bash
copy .env.example .env
npm run dev
```

## Variables de entorno

- `PORT`
- `DATABASE_URL`
- `DATABASE_SSL`
- `API_DEMO_EMAIL`
- `API_DEMO_PASSWORD`
- `API_DEMO_DISPLAY_NAME`
- `FTP_HOST`
- `FTP_PORT`
- `FTP_USER`
- `FTP_PASSWORD`
- `FTP_SECURE`

## Endpoints iniciales

- `GET /health`
- `POST /api/v1/auth/login`
- `GET /api/v1/profiles`
- `POST /api/v1/profiles`
- `GET /api/v1/files/remote`
- `POST /api/v1/sync/run`
- `GET /api/v1/sync/history`
- `GET /api/v1/monitoring/summary`

## Estado actual

La API ya usa PostgreSQL para persistencia cuando se define `DATABASE_URL`.
Si no hay base de datos configurada, puede arrancar con repositorios en memoria para desarrollo local.

## Despliegue gratuito con Render

Esta API está preparada para desplegarse en Render con:

- un Web Service gratuito
- una base de datos Render Postgres gratuita

Importante:

- El Web Service free de Render es válido para demos y pruebas.
- La base de datos Render Postgres free existe, pero expira a los 30 días.
- Render permite una sola base de datos free activa por workspace.

## Cómo desplegar

1. Sube este proyecto a GitHub.
2. Crea un Blueprint en Render usando `render.yaml`.
3. Render creará el servicio web y la base de datos.
4. La variable `DATABASE_URL` se enlaza automáticamente con la base de datos.

## Credenciales demo

Por defecto la API crea un usuario demo para probar el login:

- email: `demo@hotftp.local`
- password: `demo123`

## Nota

La parte FTP sigue siendo un detalle interno del backend. Flutter debe hablar con esta API por HTTP y no con FTP directo.

