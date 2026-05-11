# HOTFTP

Aplicacion Flutter para gestionar perfiles FTP con sincronizacion manual y programada, historial tecnico, monitorizacion, versionado de archivos y autenticacion con Firebase.

## Plataformas objetivo

- Android
- iOS
- Web

Las carpetas de Linux, macOS y Windows se han eliminado para mantener el proyecto mas limpio.
Web sigue necesitando un ultimo pase de compatibilidad para eliminar dependencias directas de `dart:io`.

## Que hace

- Inicio de sesion con Firebase Auth.
- Acceso con correo/contraseña y Google.
- Vinculacion de Google con correo/contraseña en la misma cuenta.
- Recuperacion de contraseña.
- Gestion de perfiles FTP.
- Navegacion y listado de ficheros remotos.
- Sincronizacion manual y tareas programadas con definicion persistida en la API.
- Centro de salud con:
  - alertas
  - eventos
  - estadisticas de uso
  - recomendaciones automaticas
  - versionado de archivos
  - exportacion de informe tecnico

## Arquitectura

El proyecto sigue una organizacion inspirada en Clean Architecture:

- `lib/domain`
  - entidades
  - repositorios abstractos
  - casos de uso
- `lib/data`
  - datasources
  - repositorios concretos
- persistencia local SQLite para cache y soporte de compatibilidad
- `lib/presentation`
  - viewmodels
  - pantallas
  - componentes visuales
- `lib/core`
  - servicios reutilizables
  - logica transversal

La idea es mantener las dependencias apuntando hacia dentro:

- la UI no conoce detalles de Firebase o SQLite
- el dominio no depende de Flutter
- los datos implementan contratos del dominio

## Stack

- Flutter
- Provider
- Firebase Auth
- Google Sign-In
- SQLite con `sqflite`
- HTTP contra la API propia
- FTP solo en el backend Node.js

## Requisitos

- Flutter 3.10 o superior
- Dart 3.x
- Android Studio o VS Code
- Xcode para compilar iOS
- Proyecto Firebase configurado
- Un navegador compatible para Web

## Ejecutar el proyecto

1. Instala dependencias.

```bash
flutter pub get
```

2. Revisa que `lib/firebase_options.dart` apunte a tu proyecto Firebase.

3. Ejecuta la app.

```bash
flutter run
```

Si quieres lanzar especificamente Android, consulta [EJECUCION_ANDROID.md](EJECUCION_ANDROID.md).

## Persistencia

La base de datos local se usa para guardar:

- perfiles FTP
- caché local y metadatos temporales
- historico tecnico local auxiliar

Esto permite trabajar offline y mantener un centro de salud interno del sistema.

## Notas de desarrollo

- El proyecto esta pensado para que cada responsabilidad viva en su capa.
- La monitorizacion, el versionado y el historial de sync viven en la API.
- Las tareas programadas se guardan y se consultan por HTTP; la ejecucion local sigue existiendo porque necesita acceso al sistema de archivos del dispositivo.
- Las reglas automaticas crean alertas cuando detectan patrones problematicos.
- Los archivos temporales de ejecucion y caches locales se ignoran en `.gitignore`.
- La app ya no habla con FTP directo en el flujo principal; consume la API en HTTP.

## Estado

El objetivo del proyecto es servir como base de un gestor FTP profesional, defendible en TFG y facil de extender con nuevas reglas, paneles y automatizaciones.

## Monorepo

Este repositorio tambien incluye el backend en [`hotftp_api`](hotftp_api/README.md).
La API es un proyecto Node.js/TypeScript separado, pensado para desplegarse en Render y para que Flutter consuma HTTP en lugar de FTP directo.

## Conexion con la API

Por defecto Flutter apunta a la API publica de Render:

```bash
flutter run --dart-define=HOTFTP_API_BASE_URL=https://hotftp-api.onrender.com
```

Si quieres usar una API local, cambia la URL:

```bash
flutter run --dart-define=HOTFTP_API_BASE_URL=http://127.0.0.1:3000
```

## Estado de las tareas programadas

La definicion de las tareas programadas se guarda ahora en la API.
Flutter sigue ejecutando el proceso recurrente cuando la app esta viva, porque necesita acceso a las rutas locales del dispositivo.
