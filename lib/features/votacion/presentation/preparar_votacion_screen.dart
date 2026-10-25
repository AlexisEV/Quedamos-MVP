import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/utils/formato.dart';
import '../../../core/widgets/estado_vacio.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../../lugares/data/propuesta_model.dart';
import '../../lugares/data/propuestas_repository.dart';
import '../../lugares/presentation/widgets/estilo_lugar.dart';
import '../../salidas/data/salidas_repository.dart';
import '../../salidas/presentation/crear_plan_view_model.dart';
import '../data/votacion_repository.dart';
import 'preparar_votacion_view_model.dart';

// p05 preparar votacion: solo administradores en recibiendo_propuestas
class PrepararVotacionScreen extends StatelessWidget {
  const PrepararVotacionScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PrepararVotacionViewModel(
        context.read<SalidasRepository>(),
        context.read<PropuestasRepository>(),
        context.read<VotacionRepository>(),
        planId,
      )..cargar(),
      child: const _PrepararVista(),
    );
  }
}

class _PrepararVista extends StatelessWidget {
  const _PrepararVista();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PrepararVotacionViewModel>();
    final listo = vm.salida != null && vm.puedePreparar;
    return Scaffold(
      appBar: AppBar(title: const Text('Preparar votación')),
      body: _cuerpo(context, vm),
      bottomNavigationBar: listo ? const _BarraAcciones() : null,
    );
  }

  Widget _cuerpo(BuildContext context, PrepararVotacionViewModel vm) {
    final salida = vm.salida;
    if (salida != null && vm.puedePreparar) {
      return RefreshIndicator(
        onRefresh: vm.cargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.margin),
          children: [
            _Encabezado(nombrePlan: salida.plan.nombre),
            const SizedBox(height: AppSpacing.lg),
            const _SeccionLimites(),
            const SizedBox(height: AppSpacing.lg),
            const _SeccionPlazo(),
            const SizedBox(height: AppSpacing.lg),
            const _SeccionCandidatos(),
          ],
        ),
      );
    }
    if (salida != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const EstadoVacio(
            icono: Icons.lock_outline,
            titulo: 'La votación ya no se puede preparar',
            mensaje:
                'Solo los administradores preparan la votación mientras la '
                'salida recibe propuestas.',
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Volver al detalle'),
          ),
        ],
      );
    }
    if (vm.noEncontrado) {
      return const EstadoVacio(
        icono: Icons.search_off,
        titulo: 'No encontramos esta salida',
        mensaje: 'Puede que no exista o que no participes en ella.',
      );
    }
    if (vm.error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EstadoVacio(
            icono: Icons.cloud_off_outlined,
            titulo: 'No se pudo cargar la preparación',
            mensaje: vm.error,
          ),
          OutlinedButton(onPressed: vm.cargar, child: const Text('Reintentar')),
        ],
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.nombrePlan});

  final String nombrePlan;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ADMINISTRADOR · FASE PREVIA A VOTACIÓN',
              style: textos.labelSmall?.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(nombrePlan, style: textos.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Revisa las propuestas, ajusta los límites y abre la votación '
              'del grupo.',
              style: textos.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion({required this.icono, required this.texto, this.extra});

  final IconData icono;
  final String texto;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(texto, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?extra,
      ],
    );
  }
}

// textos del mockup para cada limite ajustable
(String, String) _textosLimite(LimitePlan limite) => switch (limite) {
  LimitePlan.candidatos => (
    'Candidatos para votar',
    'Elegidos entre las propuestas',
  ),
  LimitePlan.selecciones => (
    'Votos por persona',
    'Lugares que cada persona puede elegir',
  ),
  LimitePlan.actividades => (
    'Actividades finales',
    'Más votadas que pasan al itinerario',
  ),
  LimitePlan.propuestas => (limite.titulo, limite.descripcion),
};

final _estiloPaso = IconButton.styleFrom(
  backgroundColor: AppColors.surfaceContainerHigh,
  foregroundColor: AppColors.textPrimary,
  disabledBackgroundColor: AppColors.surfaceContainerLow,
  disabledForegroundColor: AppColors.textMuted,
);

class _SeccionLimites extends StatelessWidget {
  const _SeccionLimites();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PrepararVotacionViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TituloSeccion(
          icono: Icons.tune,
          texto: 'Reglas y límites del grupo',
        ),
        for (final limite in limitesPreparables) ...[
          const SizedBox(height: AppSpacing.gutterSm),
          _FilaLimite(vm: vm, limite: limite),
        ],
        if (vm.errorLimites != null) ...[
          const SizedBox(height: AppSpacing.gutterSm),
          MensajeError(mensaje: vm.errorLimites!),
        ],
      ],
    );
  }
}

class _FilaLimite extends StatelessWidget {
  const _FilaLimite({required this.vm, required this.limite});

  final PrepararVotacionViewModel vm;
  final LimitePlan limite;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final (titulo, descripcion) = _textosLimite(limite);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutterSm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: textos.titleMedium),
                  Text(
                    '$descripcion (${limite.minimo} a ${limite.maximo})',
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
      ),
    );
  }
}

class _SeccionPlazo extends StatelessWidget {
  const _SeccionPlazo();

  // fecha y hora de pared en lima, aunque el telefono use otra zona horaria
  Future<void> _elegir(BuildContext context) async {
    final vm = context.read<PrepararVotacionViewModel>();
    final hoyLima = aHoraLima(DateTime.now());
    final actual = vm.plazoVoto == null ? null : aHoraLima(vm.plazoVoto!);
    final primerDia = DateTime(hoyLima.year, hoyLima.month, hoyLima.day);
    final inicial = actual == null
        ? primerDia
        : DateTime(actual.year, actual.month, actual.day);
    final fecha = await showDatePicker(
      context: context,
      initialDate: inicial.isBefore(primerDia) ? primerDia : inicial,
      firstDate: primerDia,
      lastDate: primerDia.add(const Duration(days: 365)),
      helpText: 'Fecha límite para votar',
    );
    if (fecha == null || !context.mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: actual == null
          ? const TimeOfDay(hour: 20, minute: 0)
          : TimeOfDay(hour: actual.hour, minute: actual.minute),
      helpText: 'Hora límite (hora de Lima)',
      // es usa 24 h; es_us mantiene los textos en espanol con reloj de 12 h y a.m./p.m.
      builder: (context, hijo) => Localizations.override(
        context: context,
        locale: const Locale('es', 'US'),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: hijo!,
        ),
      ),
    );
    if (hora == null) return;
    vm.fijarPlazoVoto(
      desdeHoraLima(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PrepararVotacionViewModel>();
    final textos = Theme.of(context).textTheme;
    final plazo = vm.plazoVoto;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TituloSeccion(
          icono: Icons.timer_outlined,
          texto: 'Plazo límite de votación',
        ),
        const SizedBox(height: AppSpacing.gutterSm),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.gutterSm),
            child: Row(
              children: [
                const Icon(Icons.alarm, color: AppColors.secondary),
                const SizedBox(width: AppSpacing.gutterSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Opcional · hora de Lima',
                        style: textos.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        plazo == null
                            ? 'Sin plazo'
                            : formatearFechaHoraLima(plazo),
                        style: textos.titleMedium,
                      ),
                    ],
                  ),
                ),
                if (plazo != null)
                  IconButton(
                    tooltip: 'Quitar plazo',
                    onPressed: vm.ocupado
                        ? null
                        : () => vm.fijarPlazoVoto(null),
                    icon: const Icon(Icons.close),
                  ),
                TextButton(
                  onPressed: vm.ocupado ? null : () => _elegir(context),
                  child: Text(plazo == null ? 'Definir' : 'Cambiar'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'El plazo es informativo: la votación solo se cierra de forma manual.',
          style: textos.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        if (vm.errorPlazo != null) ...[
          const SizedBox(height: AppSpacing.gutterSm),
          MensajeError(mensaje: vm.errorPlazo!),
        ],
      ],
    );
  }
}

class _SeccionCandidatos extends StatelessWidget {
  const _SeccionCandidatos();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PrepararVotacionViewModel>();
    final textos = Theme.of(context).textTheme;
    final maximo = vm.valor(LimitePlan.candidatos);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TituloSeccion(
          icono: Icons.checklist,
          texto: 'Candidatos',
          extra: Text(
            '${vm.seleccion.length} de $maximo',
            style: textos.labelLarge?.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Activa las propuestas que entran a la votación.',
          style: textos.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (vm.propuestas.isEmpty)
          const EstadoVacio(
            icono: Icons.place_outlined,
            titulo: 'Aún no hay propuestas',
            mensaje: 'Los participantes proponen lugares desde Explorar.',
          ),
        for (final propuesta in vm.propuestas)
          _FilaCandidato(
            propuesta: propuesta,
            esPropia: propuesta.propuestoPor == vm.usuarioActualId,
            activo: vm.estaSeleccionado(propuesta.lugarId),
            onCambiar: vm.puedeAlternar(propuesta.lugarId)
                ? () => vm.alternar(propuesta.lugarId)
                : null,
          ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.gutterSm),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Una vez abierta la votación, la lista y los límites '
                  'quedarán fijos.',
                  style: textos.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilaCandidato extends StatelessWidget {
  const _FilaCandidato({
    required this.propuesta,
    required this.esPropia,
    required this.activo,
    required this.onCambiar,
  });

  final PropuestaModel propuesta;
  final bool esPropia;
  final bool activo;
  final VoidCallback? onCambiar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final categoria = propuesta.categoria;
    final autor = esPropia ? 'ti' : propuesta.nombreAutor;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutterSm),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  categoria?.colorFondo ?? AppColors.surfaceContainer,
              child: Icon(
                categoria?.icono ?? Icons.place_outlined,
                color: categoria?.colorIcono ?? AppColors.textMuted,
              ),
            ),
            const SizedBox(width: AppSpacing.gutterSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    propuesta.nombreLugar ?? 'Lugar no disponible',
                    style: textos.titleSmall,
                  ),
                  Text(
                    [
                      if (categoria != null) categoria.etiqueta,
                      TextosLugar.precioPorPersona(propuesta.precioEstimadoPen),
                    ].join(' · '),
                    style: textos.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Propuesto por $autor',
                    style: textos.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: activo,
              onChanged: onCambiar == null ? null : (_) => onCambiar!(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarraAcciones extends StatelessWidget {
  const _BarraAcciones();

  Future<void> _guardar(BuildContext context) async {
    final vm = context.read<PrepararVotacionViewModel>();
    final mensajes = ScaffoldMessenger.of(context);
    if (await vm.guardar()) {
      mensajes.showSnackBar(
        const SnackBar(content: Text('Cambios guardados.')),
      );
    }
  }

  Future<void> _abrir(BuildContext context) async {
    final vm = context.read<PrepararVotacionViewModel>();
    final mensajes = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    final total = vm.seleccion.length;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abrir votación'),
        content: Text(
          'El grupo votará entre ${total == 1 ? '1 candidato' : '$total candidatos'}. '
          'Desde ahora no se reciben propuestas y la lista y los límites '
          'quedan fijos. No se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Abrir votación'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    if (await vm.abrir()) {
      mensajes.showSnackBar(const SnackBar(content: Text('Votación abierta.')));
      navegador.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PrepararVotacionViewModel>();
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (vm.errorAccion != null) ...[
              MensajeError(mensaje: vm.errorAccion!),
              const SizedBox(height: AppSpacing.sm),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: vm.puedeGuardar ? () => _guardar(context) : null,
                    child: vm.guardando
                        ? const _Progreso()
                        : const Text('Guardar cambios'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: vm.puedeAbrir ? () => _abrir(context) : null,
                    icon: vm.abriendo
                        ? const _Progreso(claro: true)
                        : const Icon(Icons.how_to_vote_outlined),
                    label: const Text('Abrir votación'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Progreso extends StatelessWidget {
  const _Progreso({this.claro = false});

  final bool claro;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: claro ? AppColors.onPrimary : null,
      ),
    );
  }
}
