# Pruebas de widget

Aquí solo hay pruebas de widget (`testWidgets`) de la pantalla del juego.

- Cada archivo se nombra por tema, en español, y termina en `_widget_test.dart`.
- Las ayudas compartidas (dados fijos, abrir la pantalla, lanzar, elegir ancla,
  tocar celdas…) están en `../helpers.dart`; se importan con
  `import '../helpers.dart';`.
- Para ejecutarlas, desde la carpeta `frontend/`:

  ```
  flutter test test/widgets
  ```
- `cuenta_widget_test.dart`: inicio de sesión, registro y menú de cuenta con un
  servicio falso definido en el mismo archivo (no usa el servidor real).
