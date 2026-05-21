# HOTFTP

Monorepo con dos partes principales:

- `frontend/`: app Flutter
- `backend/`: API Node.js/TypeScript

## Arranque rapido

Para ejecutar la app necesitas `Flutter`.
Si quieres levantar el backend en local, entonces tambien necesitas `Node.js`.

El arranque normal es desde `frontend/`:

```bash
cd frontend
flutter run
```

Antes de ejecutar `flutter run`, selecciona el dispositivo en `Select Device` si estas usando un IDE.
Flutter te mostrara el selector de dispositivos si hay varios disponibles.
Tambien puedes abrir navegador o emuladores moviles desde ese mismo comando, segun lo que tengas configurado.
Si el dispositivo cancela la instalacion, puede aparecer un error como `INSTALL_FAILED_USER_RESTRICTED`.

## Documentacion

- [Frontend](frontend/README.md)
- [Backend](backend/README.md)
