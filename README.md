# HOTFTP

HOTFTP es una app para gestionar perfiles FTP/SFTP, sincronizar archivos y controlar el estado de los intercambios desde una interfaz visual.

## Estructura

- `frontend/`: app Flutter.
- `backend/`: API Node.js + Express + TypeScript.
- `render.yaml`: despliegue en Render.
- `HOTFTP.apk`: binario generado para pruebas o demostracion.

## Lo mas interesante

- Autenticacion con Firebase.
- Gestion de perfiles FTP/SFTP.
- Explorador de archivos local y remoto.
- Subida, descarga y sincronizacion.
- Historial, versiones, conflictos y alertas.
- Pantallas de monitorizacion y recomendaciones de salud del sistema.

## Stack

- Flutter / Dart
- Node.js / Express / TypeScript
- PostgreSQL
- Firebase Authentication

## Ejecucion local

Backend:

```bash
cd backend
npm install
npm run dev
```

El servidor arranca por defecto en `http://127.0.0.1:3000`.

Frontend:

```bash
cd frontend
flutter pub get
flutter run --dart-define=HOTFTP_API_BASE_URL=http://127.0.0.1:3000
```

## Despliegue

El repositorio incluye `render.yaml` para crear la infraestructura en Render.

## Para portfolio

Si quieres que RRHH entienda rapido el proyecto, muestra estas 4 piezas:

1. login.
2. explorador remoto.
3. detalle de una transferencia o sincronizacion.
4. pantalla de historial o monitorizacion.
