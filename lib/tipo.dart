// lib/tipo.dart

import 'color_zona.dart';

typedef PuntosPorLugar = (int primero, int segundo, int tercero);

class Color {
  final int value;
  const Color(this.value);
}

abstract class Tipo {
  Tipo({this.puntos});

  factory Tipo.deColor(ColorZona color, {PuntosPorLugar? puntos}) =>
      switch (color) {
        ColorZona.amarillo => TipoAmarillo(puntos: puntos),
        ColorZona.verde => TipoVerde(puntos: puntos),
        ColorZona.azul => TipoAzul(puntos: puntos),
        ColorZona.morado => TipoMorado(puntos: puntos),
        ColorZona.rojo => TipoRojo(puntos: puntos),
        ColorZona.gris => TipoGris(puntos: puntos),
        ColorZona.naranja => TipoNaranja(puntos: puntos),
      };

  final PuntosPorLugar? puntos;

  Color get color;
  ColorZona get colorZona;
  String get nombre;
  String get descripcion;
  bool esPosibleAgregar(List<int> actuales, int posible);
  Map<int, int> get puntuacionesPorDefecto;

  Map<int, int> get puntuaciones => switch (puntos) {
    null => puntuacionesPorDefecto,
    (final primero, final segundo, final tercero) => {
      1: primero,
      2: segundo,
      3: tercero,
    },
  };

  int calcularPuntuacion([int posicion = 1]) {
    final valor = puntuaciones[posicion];
    if (valor == null) {
      throw ArgumentError.value(
        posicion,
        'posicion',
        'La posición debe ser 1, 2 o 3.',
      );
    }
    return valor;
  }
}

class TipoAzul extends Tipo {
  TipoAzul({super.puntos});

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
  Map<int, int> get puntuacionesPorDefecto => {1: 7, 2: 5, 3: 3};
}

class TipoRojo extends Tipo {
  TipoRojo({super.puntos});

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
  Map<int, int> get puntuacionesPorDefecto => {1: 6, 2: 4, 3: 2};
}

class TipoVerde extends Tipo {
  TipoVerde({super.puntos});

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
  Map<int, int> get puntuacionesPorDefecto => {1: 4, 2: 3, 3: 2};
}

class TipoMorado extends Tipo {
  TipoMorado({super.puntos});

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
  Map<int, int> get puntuacionesPorDefecto => {1: 6, 2: 4, 3: 2};
}

class TipoAmarillo extends Tipo {
  TipoAmarillo({super.puntos});

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
  Map<int, int> get puntuacionesPorDefecto => {1: 8, 2: 6, 3: 4};
}

class TipoGris extends Tipo {
  TipoGris({super.puntos});

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
  Map<int, int> get puntuacionesPorDefecto => {1: 3, 2: 2, 3: 1};
}

class TipoNaranja extends Tipo {
  TipoNaranja({this.minimo = 1, this.maximo = 6, super.puntos}) {
    if (minimo < 1 || maximo > 6 || minimo > maximo) {
      throw ArgumentError(
        'El rango naranja debe estar entre 1 y 6 con minimo <= maximo: '
        '$minimo a $maximo.',
      );
    }
  }

  final int minimo;
  final int maximo;

  @override
  ColorZona get colorZona => ColorZona.naranja;

  @override
  Color get color => const Color(0xFFFF9800);

  @override
  String get nombre => 'Naranja';

  @override
  String get descripcion =>
      'Solo números del $minimo al $maximo; pueden repetirse';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    return posible >= minimo && posible <= maximo;
  }

  @override
  Map<int, int> get puntuacionesPorDefecto => {1: 6, 2: 4, 3: 3};
}
