# Ejecuci�n del proyecto en Android

## Estado actual

La app qued� abierta correctamente en el emulador Android `Pixel_9a` (`emulator-5554`).

## Resumen

1. Se comprob� que el proyecto es Flutter.
2. Se listaron los dispositivos disponibles.
3. Se lanz� el emulador `Pixel_9a`.
4. Se esper� a que `adb` lo detectara como `device`.
5. Se ejecut� la app con `flutter run -d emulator-5554 --dart-define=HOTFTP_USE_FAKE_FTP=true`.

## Resultado

La compilaci�n e instalaci�n terminaron bien y la app se abri� en el emulador.

## Comando usado

```bash
flutter run -d emulator-5554 --dart-define=HOTFTP_USE_FAKE_FTP=true
```

## Notas

- Se us� `Pixel_9a` porque ofrece mas margen de memoria que el emulador pequeno.
- El proceso de `flutter run` quedo en segundo plano, asi que la app sigue disponible en el emulador.