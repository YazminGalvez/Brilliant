// lib/tipo.dart

import 'color_zona.dart';

class Color {
  final int value;
  const Color(this.value);
}

abstract class Tipo {
  Tipo();

  factory Tipo.deColor(ColorZona color) => switch (color) {
    ColorZona.amarillo => TipoAmarillo(),
    ColorZona.verde => TipoVerde(),
    ColorZona.azul => TipoAzul(),
    ColorZona.morado => TipoMorado(),
    ColorZona.rojo => TipoRojo(),
  };

  Color get color;
  ColorZona get colorZona;
  String get nombre;
  String get descripcion;
  bool esPosibleAgregar(List<int> actuales, int posible);
  Map<int, int> get puntuaciones;

  int calcularPuntuacion([int posicion = 1]) {
    final puntos = puntuaciones[posicion];
    if (puntos == null) {
      throw ArgumentError.value(
        posicion,
        'posicion',
        'La posición debe ser 1, 2 o 3.',
      );
    }
    return puntos;
  }
}

class TipoAzul extends Tipo {
  @override
  ColorZona get colorZona => ColorZona.azul;

  @override
  Color get color => const Color(0xFF2196F3);

  @override
  String get nombre => 'Azul';

  @override
  String get descripcion => 'Todos los números deben ser iguales';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    return actuales.isEmpty || actuales.every((element) => element == posible);
  }

  @override
  Map<int, int> get puntuaciones => {
        1: 7,
        2: 5,
        3: 3,
      };
}

class TipoRojo extends Tipo {
  @override
  ColorZona get colorZona => ColorZona.rojo;

  @override
  Color get color => const Color(0xFFF44336);

  @override
  String get nombre => 'Roja';

  @override
  String get descripcion => 'Todos los números deben ser distintos';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    return actuales.isEmpty || actuales.every((element) => element != posible);
  }

  @override
  Map<int, int> get puntuaciones => {
        1: 6,
        2: 4,
        3: 2,
      };
}

class TipoVerde extends Tipo {
  @override
  ColorZona get colorZona => ColorZona.verde;

  @override
  Color get color => const Color(0xFF4CAF50);

  @override
  String get nombre => 'Verde';

  @override
  String get descripcion => 'Se puede colocar cualquier número';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    return true;
  }

  @override
  Map<int, int> get puntuaciones => {
        1: 4,
        2: 3,
        3: 2,
      };
}

class TipoMorado extends Tipo {
  @override
  ColorZona get colorZona => ColorZona.morado;

  @override
  Color get color => const Color(0xFF9C27B0);

  @override
  String get nombre => 'Morada';

  @override
  String get descripcion => 'Máximo dos números diferentes por zona';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    final distintos = actuales.toSet()..add(posible);
    return distintos.length <= 2;
  }

  @override
  Map<int, int> get puntuaciones => {
        1: 6,
        2: 4,
        3: 2,
      };
}

class TipoAmarillo extends Tipo {
  @override
  ColorZona get colorZona => ColorZona.amarillo;

  @override
  Color get color => const Color(0xFFFFC107);

  @override
  String get nombre => 'Amarilla';

  @override
  String get descripcion => 'Todos los números deben ser distintos';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    return actuales.isEmpty || actuales.every((element) => element != posible);
  }

  @override
  Map<int, int> get puntuaciones => {
        1: 8,
        2: 6,
        3: 4,
      };
}
