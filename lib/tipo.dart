// lib/tipo.dart

import 'color_zona.dart';

class Color {
  final int value;
  const Color(this.value);
}

abstract class Tipo {
  Tipo({this.primerLugar});

  factory Tipo.deColor(ColorZona color, {int? primerLugar}) => switch (color) {
    ColorZona.amarillo => TipoAmarillo(primerLugar: primerLugar),
    ColorZona.verde => TipoVerde(primerLugar: primerLugar),
    ColorZona.azul => TipoAzul(primerLugar: primerLugar),
    ColorZona.morado => TipoMorado(primerLugar: primerLugar),
    ColorZona.rojo => TipoRojo(primerLugar: primerLugar),
    ColorZona.gris => TipoGris(primerLugar: primerLugar),
  };

  final int? primerLugar;

  Color get color;
  ColorZona get colorZona;
  String get nombre;
  String get descripcion;
  bool esPosibleAgregar(List<int> actuales, int posible);
  Map<int, int> get puntuacionesPorDefecto;

  Map<int, int> get puntuaciones => {
    ...puntuacionesPorDefecto,
    1: ?primerLugar,
  };

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
  TipoAzul({super.primerLugar});

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
  Map<int, int> get puntuacionesPorDefecto => {
        1: 7,
        2: 5,
        3: 3,
      };
}

class TipoRojo extends Tipo {
  TipoRojo({super.primerLugar});

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
  Map<int, int> get puntuacionesPorDefecto => {
        1: 6,
        2: 4,
        3: 2,
      };
}

class TipoVerde extends Tipo {
  TipoVerde({super.primerLugar});

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
  Map<int, int> get puntuacionesPorDefecto => {
        1: 4,
        2: 3,
        3: 2,
      };
}

class TipoMorado extends Tipo {
  TipoMorado({super.primerLugar});

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
  Map<int, int> get puntuacionesPorDefecto => {
        1: 6,
        2: 4,
        3: 2,
      };
}

class TipoAmarillo extends Tipo {
  TipoAmarillo({super.primerLugar});

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
  Map<int, int> get puntuacionesPorDefecto => {
        1: 8,
        2: 6,
        3: 4,
      };
}

class TipoGris extends Tipo {
  TipoGris({super.primerLugar});

  @override
  ColorZona get colorZona => ColorZona.gris;

  @override
  Color get color => const Color(0xFF9E9E9E);

  @override
  String get nombre => 'Gris';

  @override
  String get descripcion => 'Todos los números grises deben ser iguales';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    return actuales.isEmpty || actuales.every((element) => element == posible);
  }

  @override
  Map<int, int> get puntuacionesPorDefecto => {
        1: 3,
        2: 2,
        3: 1,
      };
}
