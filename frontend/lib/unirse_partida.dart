import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/autenticacion.dart';
import 'package:frontend/multijugador.dart';
import 'package:frontend/partidas.dart';
import 'package:frontend/proveedor_autenticacion.dart';
import 'package:frontend/sala_espera.dart';

class UnirseConCodigoPage extends StatefulWidget {
  const UnirseConCodigoPage({required this.partidas, super.key});

  static const errorGeneral =
      'No se pudo entrar a la partida. Inténtalo de nuevo.';
  static const largoCodigo = 6;

  final ServicioPartidas partidas;

  @override
  State<UnirseConCodigoPage> createState() => _UnirseConCodigoPageState();
}

class _UnirseConCodigoPageState extends State<UnirseConCodigoPage> {
  final _codigo = TextEditingController();

  bool _enviando = false;
  String? _errorCodigo;
  String? _error;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _unirse() async {
    if (_enviando) return;

    final errorCodigo = ServicioPartidas.errorCodigo(_codigo.text);
    if (errorCodigo != null) {
      setState(() {
        _errorCodigo = errorCodigo;
        _error = null;
      });
      return;
    }

    setState(() {
      _enviando = true;
      _errorCodigo = null;
      _error = null;
    });

    try {
      final sala = await widget.partidas.unirse(_codigo.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              SalaEsperaPage(partidas: widget.partidas, salaInicial: sala),
        ),
      );
    } on ErrorAutenticacion catch (error) {
      if (!mounted) return;
      final proveedor = ProveedorAutenticacion.buscar(context);
      if (error.codigoServidor == 'NO_AUTORIZADO' && proveedor != null) {
        proveedor.volverAlInicio(Navigator.of(context), aviso: error.mensaje);
        return;
      }
      _mostrarFallo(error.mensaje);
    } catch (_) {
      if (!mounted) return;
      _mostrarFallo(UnirseConCodigoPage.errorGeneral);
    }
  }

  void _mostrarFallo(String mensaje) {
    setState(() {
      _error = mensaje;
      _enviando = false;
    });
  }

  void _alCambiarCodigo(String _) {
    if (_errorCodigo == null && _error == null) return;
    setState(() {
      _errorCodigo = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final error = _error;

    return PantallaClara(
      titulo: 'Unirse a una partida',
      children: [
        Text(
          'Escribe el código que te compartió el anfitrión.',
          style: TextStyle(fontSize: 15, color: colores.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        TextField(
          key: const Key('unirse-codigo'),
          controller: _codigo,
          readOnly: _enviando,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.go,
          inputFormatters: [
            LengthLimitingTextInputFormatter(UnirseConCodigoPage.largoCodigo),
            const _Mayusculas(),
          ],
          onChanged: _alCambiarCodigo,
          onSubmitted: (_) => _unirse(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
            fontFamily: 'monospace',
          ),
          decoration: InputDecoration(
            labelText: 'Código de la partida',
            hintText: 'K7M2QX',
            prefixIcon: const Icon(Icons.vpn_key_outlined),
            border: const OutlineInputBorder(),
            errorText: _errorCodigo,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          SelectableText(
            error,
            key: const Key('unirse-error'),
            style: TextStyle(color: colores.error),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('unirse-confirmar'),
          onPressed: _enviando ? null : _unirse,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: _enviando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Unirse'),
        ),
      ],
    );
  }
}

class _Mayusculas extends TextInputFormatter {
  const _Mayusculas();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue nuevo,
  ) => nuevo.copyWith(text: nuevo.text.toUpperCase());
}
