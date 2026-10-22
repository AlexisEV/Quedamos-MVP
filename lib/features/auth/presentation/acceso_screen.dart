import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/utils/validadores.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../data/auth_repository.dart';
import 'acceso_view_model.dart';

// p11 registro e inicio de sesion con correo y contrasena
class AccesoScreen extends StatelessWidget {
  const AccesoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AccesoViewModel(context.read<AuthRepository>()),
      child: const _AccesoVista(),
    );
  }
}

class _AccesoVista extends StatefulWidget {
  const _AccesoVista();

  @override
  State<_AccesoVista> createState() => _AccesoVistaState();
}

class _AccesoVistaState extends State<_AccesoVista> {
  var _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  bool _contrasenaVisible = false;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  void _cambiarModo(ModoAcceso modo) {
    // una clave nueva recrea el formulario: limpia los mensajes de validacion
    // del modo anterior y conserva lo escrito en los controladores
    setState(() => _formulario = GlobalKey<FormState>());
    context.read<AccesoViewModel>().cambiarModo(modo);
  }

  Future<void> _enviar() async {
    final vm = context.read<AccesoViewModel>();
    if (vm.enviando) return;
    if (!(_formulario.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await vm.enviar(
      nombreVisible: _nombre.text,
      correo: _correo.text,
      contrasena: _contrasena.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccesoViewModel>();
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.canvasBg,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment(0, -0.2),
            colors: [AppColors.tealSurface, AppColors.canvasBg],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margin,
                vertical: AppSpacing.lg,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    const _Encabezado(),
                    const SizedBox(height: AppSpacing.lg),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: AutofillGroup(
                          child: Form(
                            key: _formulario,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _SelectorModo(
                                  modo: vm.modo,
                                  habilitado: !vm.enviando,
                                  onCambiar: _cambiarModo,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                if (vm.esRegistro) ...[
                                  _CampoConEtiqueta(
                                    etiqueta: 'Nombre visible',
                                    child: TextFormField(
                                      controller: _nombre,
                                      enabled: !vm.enviando,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [AutofillHints.name],
                                      decoration: const InputDecoration(
                                        hintText: 'Cómo te verá tu grupo',
                                        prefixIcon: Icon(Icons.person_outline),
                                      ),
                                      validator: Validadores.nombreVisible,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                ],
                                _CampoConEtiqueta(
                                  etiqueta: 'Correo electrónico',
                                  child: TextFormField(
                                    controller: _correo,
                                    enabled: !vm.enviando,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autocorrect: false,
                                    autofillHints: const [AutofillHints.email],
                                    decoration: const InputDecoration(
                                      hintText: 'tu@correo.com',
                                      prefixIcon: Icon(Icons.mail_outline),
                                    ),
                                    validator: Validadores.correo,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _CampoConEtiqueta(
                                  etiqueta: 'Contraseña',
                                  child: TextFormField(
                                    controller: _contrasena,
                                    enabled: !vm.enviando,
                                    obscureText: !_contrasenaVisible,
                                    textInputAction: TextInputAction.done,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    autofillHints: [
                                      vm.esRegistro
                                          ? AutofillHints.newPassword
                                          : AutofillHints.password,
                                    ],
                                    onFieldSubmitted: (_) => _enviar(),
                                    decoration: InputDecoration(
                                      hintText: vm.esRegistro
                                          ? 'Mínimo ${Validadores.minContrasena} caracteres'
                                          : null,
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      suffixIcon: IconButton(
                                        tooltip: _contrasenaVisible
                                            ? 'Ocultar contraseña'
                                            : 'Mostrar contraseña',
                                        icon: Icon(
                                          _contrasenaVisible
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                        ),
                                        onPressed: () => setState(
                                          () => _contrasenaVisible =
                                              !_contrasenaVisible,
                                        ),
                                      ),
                                    ),
                                    validator: (valor) =>
                                        Validadores.contrasena(
                                          valor,
                                          esRegistro: vm.esRegistro,
                                        ),
                                  ),
                                ),
                                if (vm.error != null) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  MensajeError(mensaje: vm.error!),
                                ],
                                const SizedBox(height: AppSpacing.lg),
                                FilledButton(
                                  onPressed: vm.enviando ? null : _enviar,
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(56),
                                  ),
                                  child: vm.enviando
                                      ? const SizedBox.square(
                                          dimension: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              vm.esRegistro
                                                  ? 'Crear cuenta'
                                                  : 'Ingresar a Quedamos',
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.sm,
                                            ),
                                            const Icon(
                                              Icons.arrow_forward,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      vm.esRegistro
                                          ? '¿Ya tienes cuenta?'
                                          : '¿Aún no tienes cuenta?',
                                      style: textos.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: vm.enviando
                                          ? null
                                          : () => _cambiarModo(
                                              vm.esRegistro
                                                  ? ModoAcceso.iniciarSesion
                                                  : ModoAcceso.registrarse,
                                            ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.coral,
                                      ),
                                      child: Text(
                                        vm.esRegistro
                                            ? 'Inicia sesión'
                                            : 'Regístrate gratis',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: const Icon(Icons.groups, color: AppColors.onPrimary, size: 36),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutterSm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.tealSurface,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'AREQUIPA, PERÚ',
                style: textos.labelMedium?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '¡Hola! Organiza las mejores salidas con tus amigos',
          style: textos.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Planes grupales sin complicaciones',
          style: textos.bodyLarge?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// selector de dos opciones con fondo de pildora como en el mockup
class _SelectorModo extends StatelessWidget {
  const _SelectorModo({
    required this.modo,
    required this.habilitado,
    required this.onCambiar,
  });

  final ModoAcceso modo;
  final bool habilitado;
  final ValueChanged<ModoAcceso> onCambiar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        children: [
          _opcion(context, ModoAcceso.iniciarSesion, 'Iniciar sesión'),
          _opcion(context, ModoAcceso.registrarse, 'Registrarse'),
        ],
      ),
    );
  }

  Widget _opcion(BuildContext context, ModoAcceso valor, String texto) {
    final activo = valor == modo;
    return Expanded(
      child: Semantics(
        selected: activo,
        button: true,
        child: Material(
          color: activo ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.full),
            onTap: habilitado ? () => onCambiar(valor) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.gutterSm,
              ),
              child: Text(
                texto,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: activo ? AppColors.onPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CampoConEtiqueta extends StatelessWidget {
  const _CampoConEtiqueta({required this.etiqueta, required this.child});

  final String etiqueta;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          etiqueta,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}
