import 'dart:math';

class Dado {
  Dado({Random? random}) : _random = random ?? Random();

  final Random _random;
  int? _valor;

  int? get valor => _valor;

  int lanzar() {
    _valor = _random.nextInt(6) + 1;
    return _valor!;
  }
}

class Dados {
  factory Dados({required int cantidad, Random? random}) {
    if (cantidad <= 0) {
      throw ArgumentError.value(
        cantidad,
        'cantidad',
        'Debe ser mayor que cero.',
      );
    }
    return Dados._(cantidad, random);
  }

  Dados._(int cantidad, Random? random)
    : _dados = List.generate(
        cantidad,
        (_) => Dado(random: random),
        growable: false,
      );

  final List<Dado> _dados;

  List<Dado> get dados => List.unmodifiable(_dados);

  List<int> lanzar() => [for (final dado in _dados) dado.lanzar()];
}
