import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formateador_codigo.dart';
import '../../../../core/utils/validadores.dart';
import '../../../../core/widgets/mensaje_error.dart';
import '../../data/salidas_repository.dart';
import '../unirse_view_model.dart';

// p02 combinada en mis salidas: campo de codigo y boton para unirse a un plan
class TarjetaUnirse extends StatelessWidget {
  const TarjetaUnirse({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UnirseViewModel(context.read<SalidasRepository>()),
      child: const _TarjetaUnirseVista(),
    );
  }
}

class _TarjetaUnirseVista extends StatefulWidget {
  const _TarjetaUnirseVista();

  @override
  State<_TarjetaUnirseVista> createState() => _TarjetaUnirseVistaState();
}

class _TarjetaUnirseVistaState extends State<_TarjetaUnirseVista> {
  final _formulario = GlobalKey<FormState>();
  final _codigo = TextEditingController();

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _unirse() async {
    if (!_formulario.currentState!.validate()) return;
    // se quita el foco al campo y no al ambito para que la ruta no lo restaure al volver
    FocusManager.instance.primaryFocus?.unfocus();
    final vm = context.read<UnirseViewModel>();
    final resultado = await vm.unirse(_codigo.text);
    if (resultado == null || !mounted) return;
    _codigo.clear();
    if (resultado.yaParticipaba) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya participas en esta salida.')),
      );
    }
    context.push(Rutas.detallePlan(resultado.planId));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UnirseViewModel>();
    final textos = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Form(
        key: _formulario,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.vpn_key_outlined,
                  size: 20,
                  color: AppColors.coral,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Unirse a una salida', style: textos.titleSmall),
                ),
                Text(
                  'Código de ${Validadores.largoCodigo} caracteres',
                  style: textos.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.gutterSm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _codigo,
                    readOnly: vm.consultando,
                    inputFormatters: [FormateadorCodigo()],
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.go,
                    style: textos.titleMedium?.copyWith(letterSpacing: 2),
                    decoration: const InputDecoration(hintText: 'AQP48X'),
                    validator: Validadores.codigoInvitacion,
                    onChanged: (_) => vm.limpiarError(),
                    onFieldSubmitted: (_) => _unirse(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    // el tema estira los botones a todo el ancho; aqui comparte fila
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: AppColors.coral,
                      foregroundColor: AppColors.onSecondary,
                    ),
                    onPressed: vm.consultando ? null : _unirse,
                    icon: vm.consultando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: const Text('Unirme'),
                    iconAlignment: IconAlignment.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Pide el código de invitación a tus amigos para unirte a su salida.',
              style: textos.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            if (vm.error != null) ...[
              const SizedBox(height: AppSpacing.gutterSm),
              MensajeError(mensaje: vm.error!),
            ],
          ],
        ),
      ),
    );
  }
}
