import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:frontend/autenticacion.dart';
import 'package:frontend/main.dart';

class InicioSesionPage extends StatefulWidget {
  const InicioSesionPage({
    required this.servicio,
    required this.siguiente,
    this.aviso,
    super.key,
  });

  static const errorGeneral = 'No se pudo iniciar sesión. Inténtalo de nuevo.';

  final ServicioAutenticacion servicio;
  final WidgetBuilder siguiente;
  final String? aviso;

  @override
  State<InicioSesionPage> createState() => _InicioSesionPageState();
}

class _InicioSesionPageState extends State<InicioSesionPage> {
  final _formulario = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _contrasena = TextEditingController();
  late final TextEditingController _servidor;

  bool _mostrarContrasena = false;
  bool _enviando = false;
  bool _intentoEnviar = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _servidor = TextEditingController(text: widget.servicio.servidor);
    _error = widget.aviso;
  }

  @override
  void dispose() {
    _usuario.dispose();
    _contrasena.dispose();
    _servidor.dispose();
    super.dispose();
  }

  String? _validarUsuario(String? valor) =>
      (valor ?? '').trim().isEmpty ? 'Escribe tu usuario.' : null;

  String? _validarContrasena(String? valor) =>
      (valor ?? '').isEmpty ? 'Escribe tu contraseña.' : null;

  String? _validarServidor(String? valor) {
    final direccion = (valor ?? '').trim();
    if (direccion.startsWith('http://') || direccion.startsWith('https://')) {
      return null;
    }
    return 'Debe empezar por http:// o https://';
  }

  Future<void> _entrar() async {
    if (_enviando) return;

    setState(() => _intentoEnviar = true);
    if (!_formulario.currentState!.validate()) return;

    widget.servicio.servidor = _servidor.text.trim();
    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await widget.servicio.iniciarSesion(
        _usuario.text.trim(),
        _contrasena.text,
      );
      if (!mounted) return;
      TextInput.finishAutofillContext();
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute<void>(builder: widget.siguiente));
    } on ErrorAutenticacion catch (error) {
      if (!mounted) return;
      _mostrarFallo(error.mensaje);
    } catch (_) {
      if (!mounted) return;
      _mostrarFallo(InicioSesionPage.errorGeneral);
    }
  }

  void _mostrarFallo(String mensaje) {
    setState(() {
      _error = mensaje;
      _enviando = false;
      _contrasena.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final error = _error;
    final errorServidor = _validarServidor(_servidor.text);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Brilliant',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, restricciones) {
            final margen = max(24.0, (restricciones.maxWidth - 420) / 2);
            return AutofillGroup(
              child: Form(
                key: _formulario,
                autovalidateMode: _intentoEnviar
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: margen,
                    vertical: 24,
                  ),
                  children: [
                    const _MarcaDelJuego(),
                    const SizedBox(height: 24),
                    Text(
                      'Inicia sesión',
                      style: tema.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Entra con tu cuenta para jugar.',
                      style: TextStyle(
                        fontSize: 15,
                        color: colores.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      key: const Key('login-usuario'),
                      controller: _usuario,
                      validator: _validarUsuario,
                      readOnly: _enviando,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('login-contrasena'),
                      controller: _contrasena,
                      validator: _validarContrasena,
                      readOnly: _enviando,
                      obscureText: !_mostrarContrasena,
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _entrar(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          key: const Key('login-mostrar-contrasena'),
                          tooltip: _mostrarContrasena
                              ? 'Ocultar contraseña'
                              : 'Mostrar contraseña',
                          icon: Icon(
                            _mostrarContrasena
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(
                            () => _mostrarContrasena = !_mostrarContrasena,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ExpansionTile(
                      title: const Text('Servidor'),
                      subtitle: Text(
                        errorServidor ?? _servidor.text.trim(),
                        style: TextStyle(
                          color: errorServidor == null
                              ? colores.onSurfaceVariant
                              : colores.error,
                        ),
                      ),
                      leading: const Icon(Icons.dns_outlined),
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      maintainState: true,
                      children: [
                        TextFormField(
                          key: const Key('login-servidor'),
                          controller: _servidor,
                          validator: _validarServidor,
                          readOnly: _enviando,
                          autocorrect: false,
                          enableSuggestions: false,
                          keyboardType: TextInputType.url,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Dirección del servidor',
                            hintText: 'http://localhost:8080',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      SelectableText(
                        error,
                        key: const Key('login-error'),
                        style: TextStyle(color: colores.error),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('login-entrar'),
                      onPressed: _enviando ? null : _entrar,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: _enviando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Entrar'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MarcaDelJuego extends StatelessWidget {
  const _MarcaDelJuego();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final color in ColorZona.values)
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: colorDeZona(color),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0x663D5147), width: 0.7),
              ),
            ),
        ],
      ),
    );
  }
}
