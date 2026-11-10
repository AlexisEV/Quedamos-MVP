import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/utils/formato.dart';
import '../../../core/widgets/estado_vacio.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../../salidas/data/salidas_repository.dart';
import '../../votacion/data/votacion_repository.dart';
import '../data/actividad_model.dart';
import '../data/itinerario_repository.dart';
import 'revisar_itinerario_view_model.dart';
import 'widgets/bloque_presupuesto.dart';
import 'widgets/datos_actividad.dart';

// p08: los administradores ordenan, asignan fecha y hora y confirman el itinerario
class RevisarItinerarioScreen extends StatelessWidget {
  const RevisarItinerarioScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RevisarItinerarioViewModel(
        context.read<ItinerarioRepository>(),
        context.read<SalidasRepository>(),
        context.read<VotacionRepository>(),
        planId,
      )..cargar(),
      child: const _RevisarVista(),
    );
  }
}

class _RevisarVista extends StatelessWidget {
  const _RevisarVista();

  // una salida con cambios sin guardar pide confirmacion para descartarlos
  Future<void> _salir(BuildContext context) async {
    final descartar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar cambios'),
        content: const Text(
          'El orden y los horarios que no guardaste se perderán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Seguir editando'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (descartar == true && context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RevisarItinerarioViewModel>();
    return PopScope(
      canPop: !vm.hayCambios && !vm.ocupado,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !vm.ocupado) _salir(context);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Revisar itinerario')),
        body: _cuerpo(context, vm),
      ),
    );
  }

  Widget _cuerpo(BuildContext context, RevisarItinerarioViewModel vm) {
    final salida = vm.salida;
    if (salida != null) {
      return RefreshIndicator(
        onRefresh: vm.cargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.margin),
          children: [
            const _Encabezado(),
            for (final (i, actividad) in vm.actividades.indexed) ...[
              const SizedBox(height: AppSpacing.gutterSm),
              _TarjetaEditable(
                actividad: actividad,
                indice: i,
                total: vm.actividades.length,
              ),
            ],
            if (vm.estimacion != null && vm.actividades.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: BloquePresupuesto(estimacion: vm.estimacion!),
                ),
              ),
            ],
            if (vm.puedeEditar) ...[
              const SizedBox(height: AppSpacing.md),
              const _Acciones(),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
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
            titulo: 'No se pudo cargar el itinerario',
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
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RevisarItinerarioViewModel>();
    final textos = Theme.of(context).textTheme;
    final String texto;
    if (vm.confirmado) {
      texto = 'El itinerario ya está confirmado.';
    } else if (vm.empatePendiente) {
      texto =
          'Primero resuelve el empate del último puesto desde el detalle '
          'de la salida.';
    } else if (!vm.puedeEditar) {
      texto = 'Solo los administradores editan el itinerario.';
    } else if (vm.actividades.isEmpty) {
      texto = 'El itinerario no tiene actividades.';
    } else {
      texto =
          'Ordena las actividades con las flechas y asigna la fecha y hora de '
          'inicio de cada una (hora de Lima). Los cambios se ven en el grupo '
          'al guardarlos.';
    }
    return Text(
      texto,
      style: textos.bodyMedium?.copyWith(color: AppColors.textSecondary),
    );
  }
}

class _TarjetaEditable extends StatelessWidget {
  const _TarjetaEditable({
    required this.actividad,
    required this.indice,
    required this.total,
  });

  final ActividadModel actividad;
  final int indice;
  final int total;

  Future<void> _elegirInicio(BuildContext context) async {
    final vm = context.read<RevisarItinerarioViewModel>();
    final mensajes = ScaffoldMessenger.of(context);
    final ahoraLima = aHoraLima(DateTime.now());
    final primerDia = DateTime(ahoraLima.year, ahoraLima.month, ahoraLima.day);
    final actual = actividad.inicio == null
        ? null
        : aHoraLima(actividad.inicio!);
    final inicial = actual == null
        ? primerDia
        : DateTime(actual.year, actual.month, actual.day);
    final fecha = await showDatePicker(
      context: context,
      initialDate: inicial.isBefore(primerDia) ? primerDia : inicial,
      firstDate: primerDia,
      lastDate: primerDia.add(const Duration(days: 365)),
      helpText: 'Fecha de la actividad',
    );
    if (fecha == null || !context.mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: actual == null
          ? const TimeOfDay(hour: 12, minute: 0)
          : TimeOfDay(hour: actual.hour, minute: actual.minute),
      helpText: 'Hora de inicio (hora de Lima)',
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
    final error = vm.fijarInicio(
      actividad.id,
      desdeHoraLima(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute),
    );
    if (error != null) {
      mensajes.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RevisarItinerarioViewModel>();
    final editable = vm.puedeEditar && !vm.ocupado;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DatosActividad(actividad: actividad, numero: indice + 1),
            if (vm.puedeEditar) ...[
              const SizedBox(height: AppSpacing.gutterSm),
              Row(
                children: [
                  IconButton.outlined(
                    tooltip: 'Subir',
                    onPressed: editable && indice > 0
                        ? () => vm.subir(indice)
                        : null,
                    icon: const Icon(Icons.arrow_upward),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.outlined(
                    tooltip: 'Bajar',
                    onPressed: editable && indice < total - 1
                        ? () => vm.bajar(indice)
                        : null,
                    icon: const Icon(Icons.arrow_downward),
                  ),
                  const Spacer(),
                  // el tema da ancho infinito a los botones; dentro de una fila se limita
                  Flexible(
                    flex: 6,
                    child: OutlinedButton.icon(
                      onPressed: editable ? () => _elegirInicio(context) : null,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                      ),
                      icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                      label: Text(
                        actividad.inicio == null
                            ? 'Asignar fecha y hora'
                            : 'Cambiar fecha y hora',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Acciones extends StatelessWidget {
  const _Acciones();

  Future<void> _guardar(BuildContext context) async {
    final vm = context.read<RevisarItinerarioViewModel>();
    final mensajes = ScaffoldMessenger.of(context);
    if (await vm.guardar()) {
      mensajes.showSnackBar(
        const SnackBar(content: Text('Itinerario guardado.')),
      );
    }
  }

  Future<void> _confirmar(BuildContext context) async {
    final vm = context.read<RevisarItinerarioViewModel>();
    final mensajes = ScaffoldMessenger.of(context);
    final estimacion = vm.estimacion;
    final avisos = [
      if (estimacion != null && estimacion.excede)
        'La estimación (${formatearSoles(estimacion.totalEstimado)}) supera el '
            'presupuesto (${formatearSoles(estimacion.presupuestoSoles)}) por '
            'persona.',
      if (estimacion != null && estimacion.incompleta)
        'La estimación es incompleta: hay actividades sin precio conocido.',
      if (vm.hayCambios) 'Se guardarán también los cambios pendientes.',
      'La salida pasará a «Confirmado» y no se puede deshacer.',
    ];
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar itinerario'),
        content: Text(avisos.join('\n\n')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;
    if (await vm.confirmar()) {
      mensajes.showSnackBar(
        const SnackBar(content: Text('Itinerario confirmado.')),
      );
      if (context.mounted) context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RevisarItinerarioViewModel>();
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (vm.errorAccion != null) ...[
          MensajeError(mensaje: vm.errorAccion!),
          const SizedBox(height: AppSpacing.gutterSm),
        ],
        OutlinedButton(
          onPressed: vm.hayCambios && !vm.ocupado
              ? () => _guardar(context)
              : null,
          child: vm.guardando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar cambios'),
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton.icon(
          onPressed: vm.puedeConfirmar ? () => _confirmar(context) : null,
          icon: vm.confirmando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onPrimary,
                  ),
                )
              : const Icon(Icons.check_circle_outline),
          label: const Text('Confirmar itinerario'),
        ),
        if (vm.sinHorario > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Asigna fecha y hora a todas las actividades para confirmar.',
            style: textos.bodySmall?.copyWith(color: AppColors.tertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
