# Ejecucion del proyecto en Android

## Estado actual

La app quedo abierta correctamente en el emulador Android `Pixel_9a` (`emulator-5554`).

## Resumen

1. Se comprobo que el proyecto es Flutter.
2. Se listaron los dispositivos disponibles.
3. Se lanzo el emulador `Pixel_9a`.
4. Se espero a que `adb` lo detectara como `device`.
5. Se ejecuto la app con `flutter run -d emulator-5554 --dart-define=HOTFTP_USE_FAKE_FTP=true`.

## Resultado

La compilacion e instalacion terminaron bien y la app se abrio en el emulador.

## Comando usado

```bash
flutter run -d emulator-5554 --dart-define=HOTFTP_USE_FAKE_FTP=true
```

## Notas

- Se uso `Pixel_9a` porque ofrece mas margen de memoria que el emulador pequeno.
- El proceso de `flutter run` quedo en segundo plano, asi que la app sigue disponible en el emulador.

## Credenciales de desarrollo

Estas credenciales se dejan aqui solo como referencia local para pruebas.

- Firebase: `guillevr7@gmail.com` / `Pepapig7`
- FTPServer: `127.0.0.1` / `8700` / `Guill` / `123`
