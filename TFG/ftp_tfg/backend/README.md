# HOTFTP Backend

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

## Endpoints

- `GET /health`
- `POST /api/v1/auth/login`
- `GET /api/v1/profiles`
- `POST /api/v1/profiles`
- `DELETE /api/v1/profiles/:id`
- `POST /api/v1/profiles/test-connection`
- `GET /api/v1/files/remote`
- `POST /api/v1/files/upload`
- `GET /api/v1/files/download`
- `DELETE /api/v1/files/remote`
- `POST /api/v1/sync/run`
- `GET /api/v1/sync/history`
- `POST /api/v1/sync/records`
- `GET /api/v1/schedules`
- `GET /api/v1/schedules/profile`
- `POST /api/v1/schedules`
- `DELETE /api/v1/schedules/:id`
- `GET /api/v1/monitoring/summary`
- `GET /api/v1/monitoring/events`
- `POST /api/v1/monitoring/events`
- `GET /api/v1/monitoring/alerts/active`
- `POST /api/v1/monitoring/alerts`
- `POST /api/v1/monitoring/alerts/:id/acknowledge`
- `GET /api/v1/monitoring/file-versions/recent`
- `POST /api/v1/monitoring/file-versions`
- `GET /api/v1/monitoring/file-versions/latest`
- `GET /api/v1/monitoring/file-versions/history`

## Estado actual

La API ya usa PostgreSQL para persistencia cuando se define `DATABASE_URL`.
Si no hay base de datos configurada, puede arrancar con repositorios en memoria para desarrollo local.
Tambien persiste eventos, alertas, versiones de archivo, historial tecnico y definiciones de tareas programadas para que Flutter consuma todo por HTTP.

## Despliegue gratuito con Render

Esta API esta preparada para desplegarse en Render con:

- un Web Service gratuito
- una base de datos Render Postgres gratuita

Importante:

- El Web Service free de Render es valido para demos y pruebas.
- La base de datos Render Postgres free existe, pero expira a los 30 dias.
- Render permite una sola base de datos free activa por workspace.
- Las tareas de monitorizacion y guardado de schedules no necesitan un worker separado.
- La ejecucion de las tareas programadas sigue siendo responsabilidad de Flutter, porque requiere acceso al sistema de archivos local.

## Como desplegar

1. Sube este proyecto a GitHub.
2. Crea un Blueprint en Render usando el `render.yaml` de la raiz del repo.
3. Render creara el servicio web y la base de datos.
4. La variable `DATABASE_URL` se enlaza automaticamente con la base de datos.

## Checklist de produccion gratis en Render

1. Confirma que `../render.yaml` sigue apuntando a `npm install && npm run build` y `npm start`.
2. Verifica que `DATABASE_URL` queda enlazada al Postgres del blueprint.
3. Comprueba que `DATABASE_SSL=false` sigue aplicado para la instancia free.
4. Revisa `API_DEMO_EMAIL`, `API_DEMO_PASSWORD` y `API_DEMO_DISPLAY_NAME`.
5. Lanza el despliegue y prueba `GET /health`.
6. Comprueba `POST /api/v1/auth/login` con el usuario demo.
7. Verifica desde Flutter que `HOTFTP_API_BASE_URL` apunta al servicio publicado.
8. Ten presente que el plan free de Render puede dormir el servicio y que el Postgres free expira a los 30 dias.

## Credenciales demo

Por defecto la API crea un usuario demo para probar el login:

- email: `demo@hotftp.local`
- password: `demo123`

## Nota

La parte FTP sigue siendo un detalle interno del backend. Flutter debe hablar con esta API por HTTP y no con FTP directo.

Si arrancas Flutter en local, puedes apuntarlo a la API con:

```bash
flutter run --dart-define=HOTFTP_API_BASE_URL=http://127.0.0.1:3000
```
