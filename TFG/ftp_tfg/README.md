# HOTFTP

Aplicación Flutter para gestionar perfiles FTP con sincronización manual y programada, historial técnico, monitorización, versionado de archivos y autenticación con Firebase.

## Qué hace

- Inicio de sesión con Firebase Auth.
- Acceso con correo/contraseña y Google.
- Vinculación de Google con correo/contraseña en la misma cuenta.
- Recuperación de contraseña.
- Gestión de perfiles FTP.
- Navegación y listado de ficheros remotos.
- Sincronización manual y tareas programadas.
- Centro de salud con:
  - alertas
  - eventos
  - estadísticas de uso
  - recomendaciones automáticas
  - versionado de archivos
  - exportación de informe técnico

## Arquitectura

El proyecto sigue una organización inspirada en Clean Architecture:

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
  - lógica transversal

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
- Proyecto Firebase configurado

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

Si quieres lanzar específicamente Android, consulta [EJECUCION_ANDROID.md](EJECUCION_ANDROID.md).

## Persistencia

La base de datos local se usa para guardar:

- perfiles FTP
- histórico de sincronizaciones
- tareas programadas
- alertas
- eventos del sistema
- estadísticas y versionado

Esto permite trabajar offline y mantener un centro de salud interno del sistema.

## Notas de desarrollo

- El proyecto está pensado para que cada responsabilidad viva en su capa.
- La monitorización y el versionado no bloquean la sincronización.
- Las reglas automáticas crean alertas cuando detectan patrones problemáticos.
- Los archivos temporales de ejecución y cachés locales se ignoran en `.gitignore`.

## Estado

El objetivo del proyecto es servir como base de un gestor FTP profesional, defendible en TFG y fácil de extender con nuevas reglas, paneles y automatizaciones.
