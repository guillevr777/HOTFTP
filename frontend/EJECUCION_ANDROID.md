# Ejecucion del proyecto en Android

## Ejecucion en produccion

La aplicación debe arrancar en Android usando la API de producción y la cuenta Firebase de producción.

## Comando recomendado

```bash
flutter run --dart-define=HOTFTP_API_BASE_URL=https://hotftp-api.onrender.com
```

## Requisitos

- Tener Flutter instalado
- Tener un dispositivo o emulador Android disponible
- Tener acceso a Internet
- Iniciar sesión con la cuenta Firebase de producción

## Notas

- No hace falta levantar backend local.
- No hace falta usar FTP local ni credenciales de desarrollo.
- Si el dispositivo cancela la instalación, puede aparecer `INSTALL_FAILED_USER_RESTRICTED`.
