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
- Sincronizacion manual y tareas programadas.
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
  - persistencia local SQLite
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
- FTP con `ftpconnect`

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
- historico de sincronizaciones
- tareas programadas
- alertas
- eventos del sistema
- estadisticas y versionado

Esto permite trabajar offline y mantener un centro de salud interno del sistema.

## Notas de desarrollo

- El proyecto esta pensado para que cada responsabilidad viva en su capa.
- La monitorizacion y el versionado no bloquean la sincronizacion.
- Las reglas automaticas crean alertas cuando detectan patrones problematicos.
- Los archivos temporales de ejecucion y caches locales se ignoran en `.gitignore`.

## Estado

El objetivo del proyecto es servir como base de un gestor FTP profesional, defendible en TFG y facil de extender con nuevas reglas, paneles y automatizaciones.
