import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/utils/validadores.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../data/salidas_repository.dart';
import 'crear_plan_view_model.dart';

// p01 crear salida: nombre, presupuesto y limites precargados
class CrearPlanScreen extends StatelessWidget {
  const CrearPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          CrearPlanViewModel(context.read<SalidasRepository>()),
      child: const _CrearPlanVista(),
    );
  }
}

class _CrearPlanVista extends StatefulWidget {
  const _CrearPlanVista();

  @override
  State<_CrearPlanVista> createState() => _CrearPlanVistaState();
}

class _CrearPlanVistaState extends State<_CrearPlanVista> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _presupuesto = TextEditingController();

  @override
  void dispose() {
    _nombre.dispose();
    _presupuesto.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    final vm = context.read<CrearPlanViewModel>();
    if (vm.enviando) return;
    final formularioValido = _formulario.currentState?.validate() ?? false;
    if (!formularioValido || vm.errorLimites != null) return;
    FocusScope.of(context).unfocus();
    final plan = await vm.crear(
      nombre: _nombre.text,
      presupuestoSoles: Validadores.leerPresupuesto(_presupuesto.text)!,
    );
    if (plan == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plan creado. Comparte el código con tu grupo.'),
      ),
    );
    context.pushReplacement(Rutas.detallePlan(plan.id));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CrearPlanViewModel>();
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear plan')),
      body: Form(
        key: _formulario,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.margin),
          children: [
            Text('Crear nuevo plan', style: textos.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Define los datos iniciales de la salida. Al crearla serás '
              'el primer administrador y el grupo comenzará recibiendo '
              'propuestas.',
              style: textos.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _Etiqueta(texto: 'Nombre del plan', requerido: true),
            TextFormField(
              controller: _nombre,
              enabled: !vm.enviando,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Ej. Sábado en Yanahuara',
                prefixIcon: Icon(Icons.edit_calendar_outlined),
              ),
              validator: Validadores.nombrePlan,
            ),
            const SizedBox(height: AppSpacing.md),
            const _Etiqueta(texto: 'Presupuesto por persona', requerido: true),
            TextFormField(
              controller: _presupuesto,
              enabled: !vm.enviando,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: '0.00',
                // prefijo y sufijo como iconos para que se vean aun sin foco
                prefixIcon: _textoFijo(context, 'S/'),
                suffixIcon: _textoFijo(context, 'PEN'),
                helperText: 'Para las actividades de toda la salida. Transporte aparte.',
                helperMaxLines: 2,
              ),
              validator: Validadores.presupuesto,
            ),
            const SizedBox(height: AppSpacing.lg),
            _TarjetaLimites(vm: vm),
            if (vm.error != null) ...[
              const SizedBox(height: AppSpacing.md),
              MensajeError(mensaje: vm.error!),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.margin,
            AppSpacing.sm,
            AppSpacing.margin,
            AppSpacing.md,
          ),
          child: FilledButton.icon(
            onPressed: vm.enviando ? null : _crear,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            icon: vm.enviando
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.add_circle_outline),
            label: const Text('Crear plan'),
          ),
        ),
      ),
    );
  }
}

Widget _textoFijo(BuildContext context, String texto) {
  return SizedBox(
    width: 64,
    child: Center(
      child: Text(
        texto,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: AppColors.textSecondary),
      ),
    ),
  );
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, this.requerido = false});

  final String texto;
  final bool requerido;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(texto, style: textos.titleMedium)),
          if (requerido)
            Text(
              'Requerido',
              style: textos.labelMedium?.copyWith(color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}

class _TarjetaLimites extends StatelessWidget {
  const _TarjetaLimites({required this.vm});

  final CrearPlanViewModel vm;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('Límites del plan', style: textos.titleLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Valores iniciales. Candidatos, selecciones y actividades se '
              'pueden ajustar hasta abrir la votación.',
              style: textos.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            for (final limite in LimitePlan.values) ...[
              const SizedBox(height: AppSpacing.gutterSm),
              _FilaLimite(vm: vm, limite: limite),
            ],
            if (vm.errorLimites != null) ...[
              const SizedBox(height: AppSpacing.gutterSm),
              MensajeError(mensaje: vm.errorLimites!),
            ],
          ],
        ),
      ),
    );
  }
}

final _estiloPaso = IconButton.styleFrom(
  backgroundColor: AppColors.surfaceContainerHigh,
  foregroundColor: AppColors.textPrimary,
  disabledBackgroundColor: AppColors.surfaceContainerLow,
  disabledForegroundColor: AppColors.textMuted,
);

class _FilaLimite extends StatelessWidget {
  const _FilaLimite({required this.vm, required this.limite});

  final CrearPlanViewModel vm;
  final LimitePlan limite;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutterSm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(limite.titulo, style: textos.titleMedium),
                Text(
                  '${limite.descripcion} (${limite.minimo} a ${limite.maximo})',
                  style: textos.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            style: _estiloPaso,
            tooltip: 'Disminuir',
            onPressed: vm.puedeBajar(limite) ? () => vm.bajar(limite) : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '${vm.valor(limite)}',
              textAlign: TextAlign.center,
              style: textos.headlineSmall?.copyWith(color: AppColors.primary),
            ),
          ),
          IconButton.filled(
            style: _estiloPaso,
            tooltip: 'Aumentar',
            onPressed: vm.puedeSubir(limite) ? () => vm.subir(limite) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
