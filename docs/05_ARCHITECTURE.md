# 05 · Arquitectura — Quedamos MVP

Versión 1.5 · 2026-11-11 (estructura y rutas al día con el código de `semana-3`) · Versión 1.3 · 2026-10-24 · Primera iteración sin push remoto (sin FCM, Edge Functions ni Cron). v1.2: contratos implementados de errores, Perfil y Salidas (§7) y rutas de salida (§4). v1.3: Lugares y Propuestas (§7), ruta `/explorar/:lugarId` (§4) y plantilla del catálogo (§2). v1.4: Votación (§7), ruta `/salidas/:planId/votacion` (§4) y `flutter_localizations` (§5). v1.5: Cerrar votación y resultado en el detalle (§7). v1.6: Recomendaciones en Explorar (§7). v1.7: Revisar itinerario (§7) y ruta `/salidas/:planId/itinerario` (§4).

## 1. Visión general

```
Flutter app (Android + iOS, un solo código Dart)
  ├─ supabase_flutter ── Auth (correo/contraseña)
  │                   ├─ PostgREST: select con RLS
  │                   ├─ RPC: escrituras con reglas de negocio (security definer)
  │                   └─ Storage: imágenes del catálogo (opcional)
  └─ flutter_local_notifications ── avisos locales programados en el dispositivo
        ▲ se alimenta de la tabla `notificaciones` al sincronizar

Supabase
  ├─ Auth correo/contraseña («Confirm email» desactivado, sin SMTP)
  └─ PostgreSQL + RLS + funciones SQL (ver 04_DATABASE_SCHEMA.md)
       └─ las RPC crean/anulan filas de `notificaciones` según el estado del plan
```

Principio: **la base de datos es la que hace cumplir las reglas** (límites, fases, roles, privacidad de votos). La app valida para dar buena experiencia, pero nunca es la única barrera.

## 2. Estructura de carpetas

```
Quedamos_mvp/
├─ AGENTS.md                 # instrucciones para agentes (versionado desde 2026-11-11)
├─ docs/                     # memoria compartida (versionada; 07_PRESENTACION.md queda local)
├─ .gitignore
├─ env.example.json          # plantilla sin valores reales (sí se versiona)
├─ .env.json                 # valores reales locales (ignorado)
├─ pubspec.yaml
├─ analysis_options.yaml
├─ android/  ios/            # proyectos nativos; applicationId y PRODUCT_BUNDLE_IDENTIFIER = com.quedamos.app
├─ lib/
│  ├─ main.dart              # inicializa env, supabase, zonas horarias, avisos locales y runApp
│  ├─ app/
│  │  ├─ app.dart            # MaterialApp.router + providers raíz
│  │  ├─ router.dart         # go_router, StatefulShellRoute de 4 pestañas, redirección por sesión
│  │  ├─ shell_screen.dart   # scaffold con la barra inferior de 4 pestañas
│  │  └─ theme/              # app_theme.dart, app_colors.dart, app_text_styles.dart, app_spacing.dart
│  ├─ core/
│  │  ├─ config/env.dart     # lectura de String.fromEnvironment
│  │  ├─ errors/             # app_exception.dart, mapeo de códigos de rpc a mensajes
│  │  ├─ services/           # supabase_service.dart (los avisos locales viven en features/notificaciones/data/avisos_locales.dart)
│  │  ├─ utils/              # formato de soles, fechas en zona horaria
│  │  └─ widgets/            # componentes reutilizables (botones, tarjetas, estados vacío/error/carga)
│  └─ features/
│     ├─ auth/               # P11
│     ├─ salidas/            # P01, P02, P06, P12 (mis salidas, crear, unirse, detalle, grupo, asistencia)
│     ├─ lugares/            # P03, P04, P09 (explorar, ficha, recomendaciones, proponer)
│     ├─ votacion/           # P05 (preparar, votar, gestionar, resultado)
│     ├─ itinerario/         # P07, P08 (revisar, reemplazo, presupuesto)
│     ├─ notificaciones/     # P10
│     └─ perfil/             # pestaña perfil
│        (cada feature:)
│        ├─ data/            # *_repository.dart (habla con supabase), modelos *_model.dart con fromJson/toJson
│        ├─ domain/          # entidades y reglas puras si hacen falta (opcional)
│        └─ presentation/    # *_screen.dart, *_view_model.dart, widgets/ propios
├─ assets/fonts/           # plus jakarta sans 400-800 + OFL.txt
├─ design_ref/             # mockups y tokens de diseño (ignorado por git)
├─ supabase/
│  ├─ config.toml
│  ├─ migrations/            # 20261022120000_crear_tablas_base.sql ...
│  ├─ catalogo_lugares.csv   # catálogo con notas de investigación (fuente del seed); instrucciones en docs/catalogo_lugares_instrucciones.md
│  └─ seed.sql               # carga los 28 lugares del csv (idempotente)
└─ test/                     # tests de modelos, view models (fakes en fakes.dart) y pantallas con AppTheme.claro
```

Nombres de archivo `snake_case`; clases y widgets `PascalCase`; variables, funciones y propiedades `camelCase`.

## 3. Gestión de estado e inyección

- **MVVM recomendado por Flutter**: `Screen` (widget) ↔ `ViewModel` (`ChangeNotifier`) ↔ `Repository` ↔ servicio Supabase.
- Inyección y escucha con el paquete **`provider`** (`ChangeNotifierProvider`, `Provider` para repositorios). Sin otras librerías de estado salvo nueva decisión en `03_DECISIONS.md`.
- Cada ViewModel expone un estado explícito: `cargando`, `datos`, `vacio`, `error` (RNF05), y nunca marca éxito antes de recibir respuesta del servidor (RNF02).
- Botones de guardar se deshabilitan durante el envío para evitar duplicados; las RPC son idempotentes donde aplica.

## 4. Navegación (go_router)

- `StatefulShellRoute.indexedStack` con 4 ramas: `/salidas`, `/explorar`, `/notificaciones`, `/perfil` (etiquetas Mis salidas · Explorar · Avisos · Perfil). La barra vive en `lib/app/shell_screen.dart`; el `redirect` escucha `SesionViewModel` (`features/auth/presentation`) como `refreshListenable`.
- Rutas anidadas de salida (implementadas `/salidas/crear`, `/salidas/:planId`, `/salidas/:planId/votacion`, `/salidas/:planId/reemplazar/:actividadId` (P07) (Preparar o Votar según la fase) y `/salidas/:planId/itinerario` (Revisar itinerario, P08); Unirse con código (P02) es la tarjeta `widgets/tarjeta_unirse.dart` dentro de Mis salidas y Participantes (P12) va en el detalle (`widgets/tarjetas_grupo.dart`), ambos sin ruta propia; las rutas fijas como `crear` y `unirse` se declaran antes de `:planId`; tras crear, `pushReplacement` al detalle): `/salidas/crear`, `/salidas/unirse`, `/salidas/:planId`, `/salidas/:planId/votacion`, `/salidas/:planId/itinerario`, `/salidas/:planId/grupo`, `/salidas/:planId/reemplazo/:actividadId`.
- `/explorar/:lugarId` (implementada, `FichaLugarScreen`), Recomendaciones (P09) no tiene ruta propia: es el selector «Catálogo | Recomendaciones» dentro de Explorar (`seccion_recomendaciones.dart`).
- `redirect` global: sin sesión → `/acceso` (P11).
- Tocar un aviso local navega a su `ruta_destino` (guardada en el `payload`) si la sesión y la participación siguen válidas.

## 5. Compatibilidad multiplataforma (Android + iOS desde el día 1)

Reglas:
1. Solo paquetes con soporte declarado para **Android e iOS** en pub.dev. Comprobar antes de añadir y registrar la dependencia en `03_DECISIONS.md` si es relevante.
2. Prohibido `dart:io Platform` para ramificar UI sin necesidad; si se usa, cubrir ambas ramas. No usar `dart:html`.
3. Widgets Material 3 comunes en ambas plataformas; no usar diseños que dependan de botones físicos de Android (atrás) para completar un flujo: siempre hay botón de volver en pantalla.
4. Respetar `SafeArea` (notch iOS, barra de gestos Android).
5. Cada permiso nativo se configura en **ambas** plataformas en el mismo cambio.

Dependencias base previstas (todas Android + iOS):

| Paquete | Uso |
|---|---|
| `supabase_flutter` | Auth, base de datos, RPC, Storage |
| `go_router` | navegación |
| `provider` | inyección y estado |
| `flutter_local_notifications` (`^22.3.3`) | programar y mostrar avisos locales (actividad, voto, asistencia, cambio, cancelación). La 23 exige AGP 9.1.1 y `compileSdk` 37: no se usa |
| `timezone` | `zonedSchedule` con `tz.UTC` (los momentos llegan en UTC; no hace falta la zona del dispositivo) |
| `intl` | formato de fechas y soles |
| `share_plus` | hoja nativa para compartir el resumen del plan confirmado (RF09; texto plano, sin permisos nativos) |
| `flutter_localizations` (SDK) | calendario, reloj y textos de Material en español (`locale: es`; `CFBundleLocalizations` en iOS) |
| `url_launcher` | **no instalado** (abrir mapas no se aprobó) |

Configuración nativa:

| Tema | Android (`android/app/src/main/AndroidManifest.xml`, gradle) | iOS (`ios/Runner/Info.plist`, Xcode) |
|---|---|---|
| Internet | `android.permission.INTERNET` | no requiere |
| Notificaciones locales | `POST_NOTIFICATIONS` (Android 13+) con solicitud en tiempo de ejecución; `RECEIVE_BOOT_COMPLETED` y los receivers del plugin (`ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver`) para reprogramar tras reinicio; desugaring de librerías Java en gradle según el README del plugin; icono de notificación en `res/drawable` | solicitud de permiso en tiempo de ejecución con el plugin; delegado `UNUserNotificationCenter` en `AppDelegate.swift` (implementado, sin compilar en iOS). No requiere APNs ni Apple Developer |
| Programación | modo **exacto** (`exactAllowWhileIdle`) con `USE_EXACT_ALARM` (Android 13+) y `SCHEDULE_EXACT_ALARM` `maxSdkVersion="32"`; si el sistema lo rechaza se programa inexacto (decisión 2026-11-10). Implementado: desugaring `desugar_jdk_libs:2.1.4`, `RECEIVE_BOOT_COMPLETED` y receivers en el manifiesto, icono `@mipmap/ic_launcher` | iOS admite como máximo 64 avisos pendientes por app: programar solo los próximos |
| Versión mínima | `minSdk` según exija `flutter_local_notifications` | `IPHONEOS_DEPLOYMENT_TARGET` según exija el plugin |
| Mapas externos (si se aprueba) | `<queries>` para intents de geo/https | `LSApplicationQueriesSchemes` |

Entorno Android verificado (2026-10-22): Flutter 3.47.7, Gradle 9.3.1, `ndkVersion = flutter.ndkVersion` exige el **NDK 28.2.13676358**. Gradle no logra instalarlo solo y `sdkmanager` está obsoleto; se instala con `%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\bin\android.exe sdk install ndk/28.2.13676358` o desde Android Studio › SDK Manager › SDK Tools › NDK (Side by side). Cada integrante lo necesita en su PC.

Notas: no hay Mac, así que **todas las pruebas y compilaciones se hacen en Android** y la compilación iOS no se verifica en el MVP. Por eso cada paquete nuevo debe declarar soporte iOS en pub.dev y cada cambio nativo en Android debe tener su equivalente documentado para iOS.

## 6. Variables de entorno y secretos

- La app lee configuración con `String.fromEnvironment` (`lib/core/config/env.dart`; sin valores, `SupabaseService.inicializar` lanza error) y se ejecuta con:
  `flutter run --dart-define-from-file=.env.json`
- `.env.json` (ignorado) contiene `SUPABASE_URL` y `SUPABASE_ANON_KEY`. `env.example.json` (versionado) contiene las mismas claves con valores vacíos.
- Supabase CLI: `npx supabase …` (2.122.0, sin Docker). `login` y `link` ya hechos por los usuarios en esta PC; las migraciones nuevas se aplican con `npx supabase db push --linked` y se verifican con `npx supabase migration list --linked` (sin `--linked` el CLI avisa que en la próxima versión mayor apuntará a la base local).
- **Versiones de presentación (demo semanal).** Dos proyectos Supabase gratuitos: desarrollo (`ycon…`, enlazado en `Quedamos_mvp`) y demo `quedamos-demo` (`qdcq…`, enlazado en `../Quedamos_demo`). Cada carpeta tiene su propio `.env.json` y su `supabase/.temp` (ambos ignorados), así que cada `db push` va solo al proyecto de su carpeta. `Quedamos_demo` es un `git worktree` en HEAD separado sobre la etiqueta de la semana. Procedimiento al cerrar la semana N:
  0. Responsable único: la computadora de Alexis (decisión 2026-11-11); ninguna otra enlaza ni toca la demo.
  1. Usuarios: `git tag semana-N <commit>` en `Quedamos_mvp` y `git push origin semana-N` (siempre desde `Quedamos_mvp`; el worktree comparte etiquetas y remotos). Se puede crear una Release con la APK de la semana.
  2. En `Quedamos_demo`: verificar `supabase/.temp/project-ref` = demo, `git checkout --detach semana-N`, `npx supabase db push --linked` (solo agrega las migraciones nuevas) y `npx supabase migration list --linked`.
  3. Si `seed.sql` cambió, cargarlo en la demo desde `Quedamos_demo`: `npx supabase db query --remote --yes -f supabase/seed.sql` (idempotente) y verificar los conteos de `lugares`.
  4. `flutter build apk --release --dart-define-from-file=.env.json` (desde la semana 3; firmada con la clave de depuración) y copiar a `../entregas/quedamos-semanaN.apk`. La release necesita `INTERNET` en `src/main/AndroidManifest.xml` y `shared_preferences_android` ≥ 2.5.2 (reglas R8); probar que pase del splash y cargue Mis salidas.
  5. La APK usa el mismo `com.quedamos.app`: instalarla reemplaza la de desarrollo (desinstalar antes para no arrastrar la sesión del otro proyecto).
  La demo solo avanza; volver a una semana anterior exige recrear el proyecto demo. El proyecto gratuito se pausa tras una semana sin uso: abrirlo días antes de presentar.
- La **`service_role` key y la contraseña de la base de datos nunca entran en la app** ni en el repositorio.
- Si en el futuro se añade FCM, sus archivos nativos y `firebase_options.dart` ya están en `.gitignore`.

## 7. Contratos con Supabase

- **Lecturas**: `supabase.from('tabla').select(...)` filtradas por RLS. Los repositorios devuelven modelos tipados, nunca `Map` crudos a la UI.
- **Escrituras de negocio**: siempre `supabase.rpc('nombre_rpc', params: {...})` según la tabla de `04_DATABASE_SCHEMA.md` §6. Los parámetros de RPC usan prefijo `p_` en SQL.
- **Errores**: las RPC lanzan códigos (`limite_propuestas_alcanzado`, `votacion_cerrada`, `no_autorizado`, `codigo_invalido`, …); `core/errors` los traduce a mensajes en español.
- **Mapeo**: columnas `snake_case` ↔ propiedades `camelCase` en `fromJson`/`toJson`.
- **Tiempo**: se envía/recibe UTC; se muestra y programa en `America/Lima`.
- **Dinero**: `numeric` llega como `num`; se formatea `S/ 0.00`. Precio `null` = desconocido, nunca 0.
- **Registro**: `auth.signUp(email, password, data: {'nombre_visible': ...})`; con «Confirm email» desactivado la sesión queda iniciada.
- **Errores de Auth/PostgREST**: los repositorios capturan y lanzan `AppException` vía `traducirError` (`core/errors/app_exception.dart`); los view models solo leen `mensaje`. Validaciones previas compartidas en `core/utils/validadores.dart`.
- **Salidas**: `SalidasRepository` lee `participaciones` del usuario con `planes(*, participaciones(count))` embebido (rol propio + plan + tamaño del grupo → `SalidaModel`). `crearPlan` llama a la RPC con un uuid generado en el view model una sola vez (`core/utils/uuid.dart`, sin paquete) y emite en `cambios` para que Mis salidas se recargue. `unirseConCodigo` llama a la RPC y devuelve `ResultadoUnion` (`planId`, `yaParticipaba`); solo emite en `cambios` si la participación es nueva. El campo de código usa `FormateadorCodigo` (`core/utils/formateador_codigo.dart`: mayúsculas, `[A-Z0-9]`, máx. 6) y `Validadores.codigoInvitacion`. `obtenerParticipantes` lee `participaciones` con `perfiles(nombre_visible)` embebido (`ParticipanteModel`, orden creador → admins → participantes por `unido_en`) y `nombrarAdministrador` llama a la RPC; `usuarioActualId` marca la fila «Tú». Copiar código usa `Clipboard` de `flutter/services` (sin paquete). Montos con `formatearSoles` (`core/utils/formato.dart`).
- **Lugares**: `LugaresRepository` lee `lugares` (RLS: solo publicados) con columnas explícitas, `obtenerLugares()` ordenado por `nombre` y `obtenerLugar(id)` con `maybeSingle` (null = no disponible). `LugarModel` con enums `ZonaLugar`/`CategoriaLugar` (`valor` + `etiqueta`); null o texto vacío = desconocido. Ícono y colores por categoría y textos de «Desconocido» en `presentation/widgets/estilo_lugar.dart`. Recomendaciones (P09): `obtenerRecomendaciones(zona, categoria, presupuestoSoles)` con la consulta de `04_DATABASE_SCHEMA.md` §6.1 (`maxRecomendaciones = 10`); `RecomendacionesViewModel` (topes `[20, 40, 60, 100]`, marca «Ya propuesto» leyendo `obtenerDestinos()` del plan de `DestinoPropuesta` y recargando con `cambios`), creado junto a `ExplorarViewModel` en `ExplorarScreen`; vista en `widgets/seccion_recomendaciones.dart`; `TarjetaLugar.yaPropuesto`.
- **Propuestas** (`features/lugares/data`): `PropuestasRepository.obtenerPropuestas(planId)` con `lugares(nombre, categoria)` y `perfiles(nombre_visible)` embebidos (lugar null = «Lugar no disponible»); `obtenerDestinos()` lee `participaciones` con `planes!inner` filtrado por `recibiendo_propuestas` y una consulta de `propuestas` de esos planes (`DestinoPlan`: cupo propio y lugares ya propuestos); `proponer`/`retirar` llaman a las RPC y emiten el `planId` en `cambios` (el detalle se recarga). `DestinoPropuesta` (`ChangeNotifier` raíz, solo en memoria) guarda el plan destino y se limpia al cerrar sesión; «Proponer lugares» del detalle lo fija y hace `context.go('/explorar')`. Selector `widgets/selector_destino.dart` (hoja sobre el navegador raíz), barra de la ficha `widgets/barra_proponer.dart`, tarjeta del detalle `salidas/.../widgets/tarjeta_propuestas.dart`.
- **Votación** (`features/votacion`): `VotacionRepository(cliente, salidasRepository)` con `obtenerCandidatos(planId)` (`candidatos` con `lugares(nombre, categoria, precio_estimado_pen)`, orden `created_at` ascendente → `CandidatoModel`) y las RPC `actualizarLimites`, `definirCandidatos`, `definirPlazos` (UTC) y `abrirVotacion` (llama a `SalidasRepository.avisarCambio()` para que Mis salidas muestre la fase). `PrepararVotacionViewModel` + `PrepararVotacionScreen` en `/salidas/:planId/votacion` (P05 preparación; reutiliza `LimitePlan` de crear plan). El detalle carga candidatos desde `en_votacion` (`widgets/tarjeta_candidatos.dart`) y se recarga al volver de la preparación. `PlanModel` incluye `fechaLimiteVoto`/`fechaLimiteAsistencia`; `PropuestaModel` incluye `precioEstimadoPen`. Votar: `obtenerMisVotos` (lee `votos`, RLS solo propios), `obtenerTotales` (RPC `obtener_totales_votacion` → `Map` candidato → total) y `guardarVotos`; `CandidatoModel` incluye `zona`. La ruta `/salidas/:planId/votacion` abre `VotacionScreen`, que con `VotarViewModel` carga la salida y muestra `PrepararVotacionScreen` en `recibiendo_propuestas` o Votar desde `en_votacion` (cerrada o cancelada: estado vacío). `VotarViewModel`: máximo = `min(max_selecciones, nº candidatos)`, guardar solo con ≥ 1 y cambios, recarga que conserva la selección sin guardar, `totalesDesactualizados` si el voto se guardó pero los totales no se recargaron. En el detalle, `TarjetaCandidatos` muestra «Tus votos (n/m)» y «Votar»/«Cambiar mis votos» en `en_votacion`. Cerrar votación: `cerrarVotacion` (RPC `cerrar_votacion`, avisa a Mis salidas) y `resolverEmpate` (RPC `resolver_empate`); `CandidatoModel` incluye `totalVotos` y `seleccionado`; `votacion/data/resultado_votacion.dart` (`ResultadoVotacion`) ordena por votos (a igual total, orden de la lista final) y calcula `cuposPendientes` y `empatados` con la misma regla que la RPC. `DetallePlanViewModel`: `puedeCerrarVotacion`, `cerrarVotacion`, `votacionCerrada`, `resultado`, `puedeResolverEmpate`, `resolverEmpate`. La fila «Cerrar votación» está en `TarjetaGestionAdmin` (diálogo irreversible; rechazo bajo la fila) y desde `preparando_itinerario` el detalle muestra `widgets/tarjeta_resultado.dart` en lugar de Candidatos (hoja de desempate con casillas limitada a los cupos y confirmación).
- **Itinerario** (`features/itinerario`): `ItinerarioRepository(cliente, salidasRepository)` con `obtenerActividades` (`actividades_itinerario` con `lugares(nombre, categoria, zona, direccion, horario_atencion, precio_estimado_pen)`, orden `posicion` ascendente → `ActividadModel`), `obtenerEstimacion` (RPC `obtener_estimacion_presupuesto` → `EstimacionPresupuesto` con `exceso` y `uso` para la barra), `guardarItinerario` (lista completa en orden, `inicio` en UTC o null) y `confirmarPlan` (avisa a Mis salidas). `RevisarItinerarioViewModel` + `RevisarItinerarioScreen` en `/salidas/:planId/itinerario`: flechas subir/bajar, fecha (calendario) y hora de inicio con reloj de 12 h (`es_US`), `fijarInicio` rechaza instantes no futuros, «Guardar cambios», «Confirmar itinerario» (guarda lo pendiente, diálogo con exceso/incompleta e irreversibilidad; desactivado si falta una hora), recarga que conserva la edición sin guardar y aviso al salir con cambios. Edita solo un admin en `preparando_itinerario` sin empate pendiente (`ResultadoVotacion.empatePendiente`). Widgets compartidos `itinerario/presentation/widgets/datos_actividad.dart` (hora de la actividad vs atención del local, precio o «Precio desconocido», «Sin fecha/hora») y `bloque_presupuesto.dart`. En el detalle, `DetallePlanViewModel(…, itinerario:)` (parámetro opcional; los tests sin itinerario lo omiten) carga actividades y estimación desde el cierre; `widgets/tarjeta_itinerario.dart` (solo lectura, para todos) va antes del resultado, y `TarjetaGestionAdmin` muestra «Revisar itinerario» (desactivada con empate pendiente).
- **Plan acordado** (P06, `confirmado`): `DetallePlanViewModel.confirmado`, `inicioSalida` (inicio de la primera actividad) y `textoCompartido` (`salidas/presentation/resumen_compartido.dart`: nombre, código, actividades con fecha/hora, lugar y dirección, presupuesto y estimación; sin enlace). El resumen superior muestra la fecha larga (`formatearFechaLargaLima`) y «Presupuesto acordado»; `_BloqueCodigo` añade `IconButton.filled` «Compartir resumen» que llama a `SharePlus.instance.share(ShareParams(text, subject, sharePositionOrigin))` (origen para iPad; error → SnackBar). En `confirmado` se ocultan `TarjetaResultado` y `_TarjetaLimites`. `DatosActividad` muestra la dirección o «Dirección desconocida».
- **Asistencia** (RF16, P06/P12, solo `confirmado`): `ParticipanteModel.asistencia` (`EstadoAsistencia` con `valor`/`etiqueta`, `conAsistencia`); `SalidasRepository.obtenerParticipantes` lee `asistencia` y `responderAsistencia` llama a la RPC. `DetallePlanViewModel`: `puedeResponderAsistencia`, `miAsistencia`, `responderAsistencia` (actualiza la lista solo tras el servidor; error en `errorAsistencia`), `conteoAsistencia`, `plazoAsistencia`, `plazoAsistenciaVencido` (no bloquea), `puedeDefinirPlazoAsistencia` y `definirPlazoAsistencia` (usa `VotacionRepository.definirPlazos` reenviando el plazo de voto vigente; null quita). Widgets: `widgets/tarjeta_asistencia.dart` (después del resumen), `widgets/estilo_asistencia.dart` (colores, `ChipAsistencia`), conteos y barra en `TarjetaParticipantes` y fila «Plazo de asistencia» en `TarjetaGestionAdmin`. Selector común de fecha y hora de Lima con reloj de 12 h en `core/widgets/selector_fecha_hora.dart` (`elegirFechaHoraLima`).
- **Reemplazo y cancelación** (RF10, P07/P06): `ItinerarioRepository.reemplazarActividad`, `cambiarHorario` (RPC `cambiar_horario_actividad`, UTC) y `obtenerCambios` (`cambios_plan` con `anterior:lugares!lugar_anterior_id(nombre)`, `nuevo:lugares!lugar_nuevo_id(nombre)` y `perfiles(nombre_visible)`, más reciente primero → `CambioPlanModel`/`TipoCambio` en `itinerario/data/cambio_plan_model.dart`); `SalidasRepository.cancelarPlan` (avisa a Mis salidas); `PlanModel.canceladoEn`. P07: `ReemplazarActividadViewModel` + `ReemplazarActividadScreen` en `/salidas/:planId/reemplazar/:actividadId` (devuelve `true` al guardar): actividad actual con `DatosActividad`, presupuesto actual vs proyectado (`totalCon`, `incompletaCon`, `excesoCon`), candidatos no elegidos por votos y catálogo con `ChoiceChip` de zona y categoría precargados (sin lugares del itinerario; precio desconocido al final), diálogo y botón inferior «Confirmar cambio de actividad». `DetallePlanViewModel`: `cancelado`, `cambios` (en `confirmado` y `cancelado`), `puedeCambiarItinerario`, `cambiarHorario`, `puedeCancelar`, `cancelarPlan`. `TarjetaGestionAdmin` añade en `confirmado` «Reemplazar o cambiar actividad» y «Modificar fecha y hora» (hoja `_HojaActividades` + `elegirFechaHoraLima` + diálogo) y, en toda fase activa, la fila roja «Cancelar esta salida» con diálogo. `widgets/tarjeta_cambios.dart` muestra el historial. El detalle `cancelado` muestra resumen sin código, aviso «Salida cancelada el …», itinerario si lo hubo, participantes e historial.
- **Perfil**: `PerfilRepository` lee `perfiles` (`id, nombre_visible`) y toma el correo de `auth.currentUser`; la edición es `update` directo de `nombre_visible` con `select().single()` para confirmar con la fila guardada.
- **Avisos locales** (`features/notificaciones`, RF14 · P10, implementado 2026-11-10): `NotificacionesRepository` (`obtenerNotificaciones`: filas propias con `planes(nombre)`, `programada_para` descendente, máx. 200 → `NotificacionModel`/`TipoNotificacion` con `accion` del botón; `marcar` → RPC `marcar_notificaciones`). `AvisosLocales` (interfaz) y `AvisosLocalesPlugin` (`avisos_locales.dart`: canal `avisos_plan`, `zonedSchedule` exacto con respaldo inexacto, `show`, `cancel`, `cancelAll`, permiso Android/iOS, payload de arranque). `NotificacionesViewModel` global (creado en `QuedamosApp`, provisto con `ChangeNotifierProvider`): `alIniciarSesion` pide el permiso una vez por sesión y sincroniza; `sincronizar` (sin solaparse) programa las `activa` futuras con `id_local`, cancela las `anulada`, muestra `cambio`/`cancelacion` sin `entregada_en` y las marca entregadas; `historial` (activas con momento ya llegado; un temporizador hasta el siguiente aviso activo futuro redibuja historial e insignia con la app abierta, cancelado al cerrar sesión), `noLeidas`, `marcarLeida`, `marcarTodas`, `pedirPermiso`, `limpiar` (cerrar sesión → `cancelAll`). Payload `id|ruta`. Disparadores: inicio con sesión, cambio de sesión, `AppLifecycleListener.onResume`, deslizar en P10 y `SalidasRepository.cambiosDeAvisos` (emitido por `avisarCambio` y por `avisarCambioDeAvisos` en guardar votos, asistencia, plazos, reemplazo, horario y unirse). Tocar un aviso del sistema → `_router.go(ruta)` y marca leído. P10 (`notificaciones_screen.dart`): tarjeta de permiso (activado / «Activar avisos» / indicación de Ajustes), cabecera con «n nuevas» y «Leídas», `TarjetaAviso` por tipo (borde, ícono, chip del plan, hora de Lima, punto de no leído, botón que hace `context.go(ruta_destino)`), vacío y error con reintento. `ShellScreen` muestra `Badge` con `noLeidas` en Avisos. Preparar votación indica el aviso 1 h antes del plazo.

## 8. De Figma (vía MCP o capturas) a widgets Flutter

**Regla de jerarquía (obligatoria).** Los mockups de Figma son **referencia visual y de estructura de UI**. No están 100 % alineados con las pantallas P01–P12. Ante cualquier discrepancia entre un mockup y `06_REQUIREMENTS.md` (campos, acciones, reglas, textos de comportamiento, flujos), **el agente se detiene y consulta a los usuarios** si prevalece `06_REQUIREMENTS.md` o si debe modificarse para adecuarse al mockup. Registrar la respuesta en `03_DECISIONS.md` (y actualizar `06_REQUIREMENTS.md` si cambia).

Fuente de diseño local: `design_ref/` (ignorada por git): `DESIGN.md` con tokens, `code.html`, `screen.png` y `figma/*.png`. Tokens ya llevados a `lib/app/theme/` (esquema M3 del YAML de `DESIGN.md` + colores de contexto). Fuente Plus Jakarta Sans 400–800 en `assets/fonts/` (OFL, sin paquete `google_fonts`).

Lineamientos:
1. Antes de maquetar, identificar a qué `P` corresponde el frame y leer su ficha en `06_REQUIREMENTS.md` §9.
2. Extraer primero **tokens** (colores, tipografías, espaciados, radios) a `lib/app/theme/`; nunca valores mágicos repetidos en las pantallas.
3. Componentes repetidos en Figma (tarjeta de lugar, chip de estado, barra inferior, tarjeta de plan) → widgets en `lib/core/widgets/` o `features/<x>/presentation/widgets/`.
4. Traducir Auto Layout a `Column`/`Row`/`Wrap` con `Padding`/`Gap`; evitar posicionamiento absoluto y tamaños fijos que rompan en otras pantallas.
5. Textos de ejemplo del mockup (lugares, precios, horarios, personas) **no** son datos reales ni reglas: los datos vienen del backend.
6. Implementar todos los estados de la ficha P (carga, vacío, error, etc.) aunque el mockup solo muestre el estado con datos.
7. Imágenes/íconos exportados se guardan en `assets/` con nombres `snake_case`; preferir íconos de Material.

Discrepancias ya conocidas entre mockups y requisitos (consultar antes de implementar si aparecen):
- Acceso con **Google** en mockups → requisitos: solo correo y contraseña.
- Cualquier texto o botón de **WhatsApp** → fuera de alcance.
- Enlace **«¿Olvidaste tu contraseña?»** o pantalla de confirmación de correo → fuera de alcance.
- Límites en Crear plan → alineado: los 4 límites aparecen precargados y editables en Crear plan (con sus rangos) y candidatos/selecciones/actividades también en _Preparar votación_.
- Textos que sugieran **cierre automático** de votación o reservas → el cierre es manual y no hay reservas.
- Reemplazo que **recalcula horarios** automáticamente → no aprobado.
- Totales de votos de ejemplo imposibles (más votos que participantes × selecciones) → los totales vienen del servidor.
