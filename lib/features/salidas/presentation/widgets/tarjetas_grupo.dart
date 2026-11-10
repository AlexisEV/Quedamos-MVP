import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formato.dart';
import '../../../../core/widgets/mensaje_error.dart';
import '../../../../core/widgets/selector_fecha_hora.dart';
import '../../data/participante_model.dart';
import '../detalle_plan_view_model.dart';
import 'estilo_asistencia.dart';

// p12 integrada en el detalle: lista del grupo con su rol y, confirmado, su asistencia
class TarjetaParticipantes extends StatelessWidget {
  const TarjetaParticipantes({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DetallePlanViewModel>();
    final textos = Theme.of(context).textTheme;
    final participantes = vm.participantes;
    final conAsistencia = vm.confirmado;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.group_outlined, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Participantes (${participantes.length})',
                  style: textos.titleLarge,
                ),
              ],
            ),
            if (conAsistencia && participantes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.gutterSm),
              const _ResumenAsistencia(),
            ],
            const SizedBox(height: AppSpacing.sm),
            for (final participante in participantes)
              _FilaParticipante(
                participante: participante,
                esUsuarioActual: participante.perfilId == vm.usuarioActualId,
                propuestas: vm.propuestasDe(participante.perfilId),
                maxPropuestas: vm.salida?.plan.maxPropuestasPorPersona ?? 0,
                conAsistencia: conAsistencia,
              ),
          ],
        ),
      ),
    );
  }
}

class _FilaParticipante extends StatelessWidget {
  const _FilaParticipante({
    required this.participante,
    required this.esUsuarioActual,
    required this.propuestas,
    required this.maxPropuestas,
    this.conAsistencia = false,
  });

  final ParticipanteModel participante;
  final bool esUsuarioActual;
  final int propuestas;
  final int maxPropuestas;
  // con el plan confirmado la asistencia reemplaza al conteo de propuestas
  final bool conAsistencia;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          _Avatar(participante: participante),
          const SizedBox(width: AppSpacing.gutterSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        participante.nombreVisible,
                        overflow: TextOverflow.ellipsis,
                        style: textos.titleSmall,
                      ),
                    ),
                    if (esUsuarioActual) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const _InsigniaTu(),
                    ],
                  ],
                ),
                Text(
                  participante.etiquetaRol,
                  style: textos.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (conAsistencia)
            ChipAsistencia(estado: participante.asistencia)
          else
            // solo el conteo: proponer no es obligatorio, no hay pendientes
            Text(
              '$propuestas/$maxPropuestas propuestas',
              style: textos.labelMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.participante});

  final ParticipanteModel participante;

  @override
  Widget build(BuildContext context) {
    final nombre = participante.nombreVisible;
    final inicial = nombre.isEmpty ? '' : nombre.characters.first.toUpperCase();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.tealSurface,
          child: Text(
            inicial,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: AppColors.primary),
          ),
        ),
        // estrella de administrador como en el mockup
        if (participante.esAdministrador)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star,
                size: 10,
                color: AppColors.onPrimary,
              ),
            ),
          ),
      ],
    );
  }
}

class _InsigniaTu extends StatelessWidget {
  const _InsigniaTu();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        'Tú',
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: AppColors.primary),
      ),
    );
  }
}

// acciones de administrador: preparar la votacion (rf05, rf18) y nombrar administradores (rf17)
// conteos del grupo y barra de tres tonos, como el mockup del detalle confirmado
class _ResumenAsistencia extends StatelessWidget {
  const _ResumenAsistencia();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DetallePlanViewModel>();
    final textos = Theme.of(context).textTheme;
    final asistiran = vm.conteoAsistencia(EstadoAsistencia.asistire);
    final pendientes = vm.conteoAsistencia(EstadoAsistencia.pendiente);
    final noAsistiran = vm.conteoAsistencia(EstadoAsistencia.noAsistire);
    final partes = [
      (
        EstadoAsistencia.asistire,
        asistiran,
        asistiran == 1 ? '1 asistirá' : '$asistiran asistirán',
      ),
      (
        EstadoAsistencia.pendiente,
        pendientes,
        pendientes == 1 ? '1 pendiente' : '$pendientes pendientes',
      ),
      (
        EstadoAsistencia.noAsistire,
        noAsistiran,
        noAsistiran == 1 ? '1 no asistirá' : '$noAsistiran no asistirán',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.gutterSm,
          runSpacing: AppSpacing.xs,
          children: [
            for (final (estado, _, texto) in partes)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: estado.colorBarra,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    texto,
                    style: textos.labelMedium?.copyWith(color: estado.color),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: SizedBox(
            height: 8,
            // stretch da alto a los segmentos, que no tienen hijo
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (estado, cantidad, _) in partes)
                  if (cantidad > 0)
                    Expanded(
                      flex: cantidad,
                      child: ColoredBox(color: estado.colorBarra),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TarjetaGestionAdmin extends StatelessWidget {
  const TarjetaGestionAdmin({super.key});

  // fija o quita el plazo de asistencia; no bloquea respuestas (rf16)
  Future<void> _plazoAsistencia(BuildContext context) async {
    final vm = context.read<DetallePlanViewModel>();
    final mensajes = ScaffoldMessenger.of(context);
    final actual = vm.plazoAsistencia;
    var quitar = false;
    if (actual != null) {
      final opcion = await showModalBottomSheet<String>(
        context: context,
        useRootNavigator: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_calendar_outlined),
                title: const Text('Cambiar fecha y hora'),
                onTap: () => Navigator.of(context).pop('cambiar'),
              ),
              ListTile(
                leading: const Icon(Icons.timer_off_outlined),
                title: const Text('Quitar plazo'),
                onTap: () => Navigator.of(context).pop('quitar'),
              ),
            ],
          ),
        ),
      );
      if (opcion == null || !context.mounted) return;
      quitar = opcion == 'quitar';
    }
    DateTime? plazo;
    if (!quitar) {
      plazo = await elegirFechaHoraLima(
        context,
        actual: actual,
        tituloFecha: 'Fecha límite de asistencia',
        tituloHora: 'Hora límite (hora de Lima)',
      );
      if (plazo == null) return;
    }
    if (await vm.definirPlazoAsistencia(plazo)) {
      mensajes.showSnackBar(
        SnackBar(
          content: Text(
            quitar ? 'Plazo quitado.' : 'Plazo de asistencia guardado.',
          ),
        ),
      );
    }
  }

  Future<void> _nombrar(BuildContext context) async {
    final vm = context.read<DetallePlanViewModel>();
    final mensajes = ScaffoldMessenger.of(context);
    final elegido = await showModalBottomSheet<ParticipanteModel>(
      context: context,
      // sobre el navegador raiz para que la barra de pestanas no la tape
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) => _HojaNombrables(nombrables: vm.nombrables),
    );
    if (elegido == null || !context.mounted) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nombrar a ${elegido.nombreVisible}'),
        content: const Text(
          'Podrá gestionar la salida como administrador. '
          'El rol es permanente y no se puede retirar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Nombrar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    final guardado = await vm.nombrarAdministrador(elegido);
    if (guardado) {
      mensajes.showSnackBar(
        SnackBar(
          content: Text('${elegido.nombreVisible} ahora es administrador.'),
        ),
      );
    }
  }

  // al volver se recarga el detalle: pudieron cambiar limites, candidatos o fase
  Future<void> _prepararVotacion(BuildContext context) async {
    final vm = context.read<DetallePlanViewModel>();
    await context.push(Rutas.votacion(vm.planId));
    await vm.cargar();
  }

  // al volver se recarga el detalle: pudieron cambiar orden, horarios o fase
  Future<void> _revisarItinerario(BuildContext context) async {
    final vm = context.read<DetallePlanViewModel>();
    await context.push(Rutas.itinerario(vm.planId));
    await vm.cargar();
  }

  Future<void> _cerrarVotacion(BuildContext context) async {
    final vm = context.read<DetallePlanViewModel>();
    final mensajes = ScaffoldMessenger.of(context);
    final actividades = vm.salida?.plan.maxActividades ?? 0;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar votación'),
        content: Text(
          'Ya no se aceptarán votos y la votación no se puede reabrir. '
          'Pasan al itinerario los lugares más votados, hasta $actividades; '
          'si hay empate en el último puesto, un administrador elige.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar votación'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    if (await vm.cerrarVotacion()) {
      mensajes.showSnackBar(const SnackBar(content: Text('Votación cerrada.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DetallePlanViewModel>();
    final textos = Theme.of(context).textTheme;
    final hayNombrables = vm.nombrables.isNotEmpty;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Gestión de administrador', style: textos.titleLarge),
              ],
            ),
            if (vm.puedePrepararVotacion) ...[
              const SizedBox(height: AppSpacing.gutterSm),
              Material(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: ListTile(
                  shape: forma,
                  leading: const Icon(Icons.how_to_vote_outlined),
                  title: const Text('Preparar votación'),
                  subtitle: const Text(
                    'Candidatos, límites, plazo y apertura de la votación',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _prepararVotacion(context),
                ),
              ),
            ],
            if (vm.puedeCerrarVotacion) ...[
              const SizedBox(height: AppSpacing.gutterSm),
              Material(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: ListTile(
                  shape: forma,
                  enabled: !vm.cerrando,
                  leading: vm.cerrando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_outline),
                  title: const Text('Cerrar votación'),
                  subtitle: const Text(
                    'Cierre manual e irreversible; el plazo no la cierra solo',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _cerrarVotacion(context),
                ),
              ),
              if (vm.errorCierre != null) ...[
                const SizedBox(height: AppSpacing.gutterSm),
                MensajeError(mensaje: vm.errorCierre!),
              ],
            ],
            if (vm.puedeRevisarItinerario) ...[
              const SizedBox(height: AppSpacing.gutterSm),
              Material(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: ListTile(
                  shape: forma,
                  enabled: !vm.itinerarioBloqueadoPorEmpate,
                  leading: const Icon(Icons.route_outlined),
                  title: const Text('Revisar itinerario'),
                  subtitle: Text(
                    vm.itinerarioBloqueadoPorEmpate
                        ? 'Primero resuelve el empate del último puesto'
                        : 'Orden, fecha y hora, presupuesto y confirmación',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _revisarItinerario(context),
                ),
              ),
            ],
            if (vm.puedeDefinirPlazoAsistencia) ...[
              const SizedBox(height: AppSpacing.gutterSm),
              Material(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: ListTile(
                  shape: forma,
                  enabled: !vm.guardandoPlazo,
                  leading: vm.guardandoPlazo
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.timer_outlined),
                  title: const Text('Plazo de asistencia'),
                  subtitle: Text(_textoPlazo(vm)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _plazoAsistencia(context),
                ),
              ),
              if (vm.errorPlazo != null) ...[
                const SizedBox(height: AppSpacing.gutterSm),
                MensajeError(mensaje: vm.errorPlazo!),
              ],
            ],
            const SizedBox(height: AppSpacing.gutterSm),
            Material(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: ListTile(
                shape: forma,
                enabled: hayNombrables && !vm.asignando,
                leading: vm.asignando
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_alt_1_outlined),
                title: const Text('Nombrar nuevo administrador'),
                subtitle: hayNombrables
                    ? null
                    : const Text('Todos los participantes ya administran.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _nombrar(context),
              ),
            ),
            if (vm.errorAsignacion != null) ...[
              const SizedBox(height: AppSpacing.gutterSm),
              MensajeError(mensaje: vm.errorAsignacion!),
            ],
          ],
        ),
      ),
    );
  }
}

String _textoPlazo(DetallePlanViewModel vm) {
  final plazo = vm.plazoAsistencia;
  if (plazo == null) return 'Sin plazo · opcional, no bloquea respuestas';
  final fecha = formatearFechaHoraLima(plazo);
  return vm.plazoAsistenciaVencido ? 'Vencido: $fecha' : 'Hasta $fecha';
}

class _HojaNombrables extends StatelessWidget {
  const _HojaNombrables({required this.nombrables});

  final List<ParticipanteModel> nombrables;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text('Elige a un participante', style: textos.titleMedium),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final participante in nombrables)
            ListTile(
              leading: _Avatar(participante: participante),
              title: Text(participante.nombreVisible),
              subtitle: Text(participante.etiquetaRol),
              onTap: () => Navigator.of(context).pop(participante),
            ),
        ],
      ),
    );
  }
}
