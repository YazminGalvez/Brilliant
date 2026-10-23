# Brilliant

Juego de dados Brilliant para un jugador, sobre un tablero de 7x7.

## Estructura

- Raíz (`juego_brilliant`): lógica de dominio en Dart puro (`lib/`) y sus pruebas (`test/`).
- `frontend/`: interfaz en Flutter que usa el paquete de la raíz.

## Pruebas

```sh
# Dominio (en la raíz)
dart test

# Interfaz
cd frontend
flutter test
```
