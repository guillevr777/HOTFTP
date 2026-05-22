# HOTFTP

HOTFTP es una app Flutter que funciona en producción con Firebase y con una API desplegada en Render.

## Despliegue en Render

Puedes crear la API y la base de datos directamente desde este repositorio con el Blueprint de Render.

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/guillevr777/HOTFTP)

El archivo que genera la infraestructura es [render.yaml](/C:/Users/guill/Documents/HOTFTP/TFG/ftp_tfg/render.yaml).

## Qué crea Render

- Una base de datos PostgreSQL llamada `hotftp-db`
- Un servicio web llamado `hotftp-api`
- La variable `DATABASE_URL` enlazada automáticamente a la base de datos

## Requisitos

- Flutter 3.10 o superior
- Dart 3.x
- Android Studio o VS Code si vas a usar Android
- Xcode si vas a compilar iOS en macOS
- Acceso a la cuenta Firebase de producción
- Conexión a Internet para consumir la API de Render

## Ejecución desde cero

1. Instala Flutter y comprueba que `flutter doctor` no tenga errores bloqueantes.
2. Abre una terminal en la raíz del proyecto.
3. Descarga dependencias del frontend:

```bash
cd frontend
flutter pub get
```

4. Ejecuta la app contra la API de producción:

```bash
flutter run --dart-define=HOTFTP_API_BASE_URL=https://hotftp-api.onrender.com
```

5. Inicia sesión con la cuenta Firebase de producción.

## Configuración de producción

- Firebase de producción: configurado en `frontend/lib/firebase_options.dart`
- API de producción: `https://hotftp-api.onrender.com`
- La app no necesita backend local ni credenciales de prueba para funcionar.
- La base de datos, los perfiles y la lógica de la API residen en Render.

## Credenciales de producción

- Firebase: `guillevr7@gmail.com` / `Pepapig7`

## Rutas útiles

- Ruta local inicial en Android: `/storage/emulated/0`
- Ruta remota inicial: `/`
- API de producción: `https://hotftp-api.onrender.com`

## Notas

- El frontend consume la API por HTTP y no usa FTP directo en el flujo principal.
- Las tareas programadas se guardan en la API, pero su ejecución sigue dependiendo de Flutter porque necesita acceso al sistema de archivos local.
- Si abres la app en otro ordenador, solo necesitas Flutter, conexión a Internet, Firebase de producción y la URL de Render.
