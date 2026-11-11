# branding

Assets de marca para pulso-mobile.

- `pulso_icon.png` (1024x1024): icono de app, cuadrado, verde eucalipto
  con el trazo del EKG en mostaza. Lo usa `flutter_launcher_icons` para
  generar los `mipmap-*` de android y el AppIcon.appiconset de ios.
- `pulso_icon_fg.png` (1024x1024): capa foreground para el adaptive
  icon de android 8+. Fondo transparente, solo el trazo.
- `pulso_splash.png` (1024x1024): version centrada para el splash. Se
  escala en todas las densidades.

Para regenerar los assets nativos despues de cambiar el PNG:

```
dart run flutter_native_splash:create
dart run flutter_launcher_icons
```

Si cambia la paleta tambien hay que actualizar los colores en el
bloque `flutter_native_splash` del pubspec.
