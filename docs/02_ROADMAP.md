# 02 · Roadmap del MVP — 3 semanas de desarrollo + 1 de estabilización

Inicio: 2026-10-21 · **MVP 100 % funcional (feature complete): 2026-11-12** · Colchón de estabilización: 2026-11-13 → **2026-11-19**.
Capacidad: **máx. 7 h/semana por integrante ≈ 14 h/semana** → ~46 h hasta el 11-12 (la semana 3 dura 9 días, ~18 h) + ~14 h de colchón.
Equipo: A (interfaz Flutter/navegación) y B (base de datos/RLS/RPC/avisos), con revisión cruzada. Roles intercambiables.
Pruebas y compilación: solo Android. Código y `pubspec.yaml` compatibles con iOS (ver `05_ARCHITECTURE.md` §5). Identificador: `com.quedamos.app`.

**Estrategia.** Todo el alcance funcional de `06_REQUIREMENTS.md` termina el **2026-11-12**, listo para entregar si el profesor pide el MVP en 3 semanas. La semana 4 **no incluye funciones nuevas**: solo pruebas de usuario, corrección de bugs y pulido visual.

**Regla de avance.** Una tarea se marca `[x]` solo cuando interfaz y backend están conectados, los permisos se aplican en servidor y el recorrido se probó en Android. Cada semana cierra con una demo de su entregable. Las horas son estimaciones (A/B); si una semana se excede, avisar en `01_STATE.md` antes de recortar.

Códigos: RF y P según `06_REQUIREMENTS.md`.

---

## Semana 1 (2026-10-21 → 10-27) · Base, cuentas y planes · ~14 h

Entregable: dos cuentas en Android se registran, crean un plan, lo comparten por código y se unen; un participante pasa a administrador.

**Estado (2026-10-24): completa.** Etiqueta `semana-1` (`5fa81c1`) desplegada en el proyecto demo y APK `quedamos-semana1.apk` probada por los usuarios (ver `05_ARCHITECTURE.md` §6).

- [x] (B, 1 h) Proyecto Supabase gratuito, Supabase CLI, «Confirm email» desactivado en Auth.
- [x] (A, 1 h) `flutter create --org com.quedamos --project-name app --platforms=android,ios` (verificar `applicationId` y `PRODUCT_BUNDLE_IDENTIFIER` = `com.quedamos.app`), estructura de `05_ARCHITECTURE.md`, `analysis_options.yaml`, `env.example.json`.
- [x] (B, 2 h) Migración base: enums, `perfiles` (trigger con `nombre_visible`), `planes`, `participaciones`, helpers y RLS.
- [x] (A, 2 h) Shell de 4 pestañas (Mis salidas, Explorar, Avisos, Perfil), redirect por sesión y tema base desde Figma. _Verificado en Android con sesión real (2026-10-22); corregido el color del título del AppBar._
- [x] (A, 2 h) Registro (nombre visible, correo, contraseña), inicio y cierre de sesión, restauración de sesión — RF15 · P11 · Perfil. _Verificado en Android con 2 cuentas de prueba (2026-10-22)._
- [x] (B+A, 3 h) Mis salidas + Crear plan (nombre, presupuesto, límites precargados con rangos) + RPC `crear_plan` + detalle con código y _Copiar código_ — RF01, RF18 · P01, P06. _Verificado en Android (2026-10-22), incluido pegar el código copiado. Commit `1c0a893`._
- [x] (B+A, 2 h) Unirse con código (6 caracteres, mayúsculas) + RPC `unirse_con_codigo` idempotente — RF02 · P02. _Verificado en Android con la cuenta 2 (2026-10-23): código inválido, `twomoy` en minúsculas y repetición sin duplicar._
- [x] (B+A, 1 h) Participantes y roles + RPC `nombrar_administrador` — RF17 · P12. _Verificado en Android (2026-10-23): la cuenta 2 como participante no ve la gestión; la cuenta 1 nombra administradora a la cuenta 2 y el rol persiste tras recargar. Permisos de la RPC verificados en servidor con SQL revertido (participante → `no_autorizado`)._

## Semana 2 (2026-10-28 → 11-03) · Lugares, propuestas y votación · ~14 h

Entregable: cada participante propone (o retira) lugares en el plan correcto; el administrador prepara la votación; el grupo vota, ve totales sin identidades y el administrador cierra y desempata.

- [x] (B, 2 h) Migración `lugares` + `seed.sql` con 20–30 lugares reales (5 zonas, 4 categorías, fuente y fecha de revisión) — RF11. _Migración aplicada en desarrollo y RLS verificada (2026-10-24). Seed de 28 lugares generado desde `catalogo_lugares.csv` y cargado en desarrollo (2026-10-25); conteos verificados y segunda carga sin duplicados. Cargado en la demo al cerrar la semana 2 (2026-11-03, 28 lugares verificados)._
- [x] (A, 2 h) Explorar lugares y ficha (datos conocidos vs desconocidos, precio estimado) — RF03, RF04 · P03, P04. _Verificadas en Android con el seed real (2026-10-25); corregido el orden alfabético (`order` descendía por defecto). «Desconocido» cubierto solo por tests: el seed no tiene datos vacíos._
- [x] (A, 1 h) Recomendaciones: zona + categoría + presupuesto obligatorios, precio ≤ presupuesto, orden ascendente, máx. 10 — RF13 · P09. _Lectura directa sin migración; selector «Catálogo \| Recomendaciones» en Explorar y topes fijos 20/40/60/100 (`03_DECISIONS.md` 2026-11-03); 114 tests. En Android (2026-11-03) con el seed real: Yanahuara + Cafés hasta S/ 40 → Chaqchao (20) y BAWi (22); hasta S/ 20 incluye el tope; Restaurantes hasta S/ 20 → «Sin opciones compatibles»; ficha desde el resultado y vuelta conservando la lista. Solo por tests: máximo 10 (ninguna combinación del seed pasa de 4), error y «Ya propuesto» (no hay planes en `recibiendo_propuestas`)._
- [x] (B+A, 2 h) Proponer con selector de plan destino, «Ya propuesto», retiro por autor/admin + RPC `proponer_lugar` y `retirar_propuesta` — RF05 · P04, P05, P09. _Migración aplicada y reglas verificadas en servidor; app con 66 tests; en Android verificados la tarjeta Propuestas, «Proponer lugares» → Explorar y el selector (2026-10-24). Commit `49336d6`. Proponer y retirar verificados en Android con el seed real y ambas cuentas (2026-10-25); propuestas ordenadas de la más antigua a la más reciente. «Ya propuesto» en Recomendaciones (P09) llega con RF13._
- [x] (B+A, 2 h) Preparar votación: candidatos, límites, fecha límite de voto opcional, abrir votación — RF05, RF18 · P05. _Migración `preparar_votacion` aplicada en desarrollo y reglas verificadas con SQL revertido; 86 tests (incluye el reloj de 12 h del plazo y la recarga que conserva lo no guardado). En Android (2026-10-25, cuenta 2): guardar candidatos y plazo (verificado en servidor), abrir con confirmación en «Prueba Yanahuara», detalle con «Candidatos (2)» fijos y Mis salidas «En votación». Los usuarios abrieron «Prueba hora» y confirmaron el reloj de 12 h; la vista del participante se revisa en Votar. Commit `971bfd5`._
- [x] (B+A, 3 h) Votar: selección múltiple con contador, `guardar_votos`, selección propia y totales sin identidad — RF06, RF07 · P05. _Migración `votar` (tabla `votos`, `guardar_votos`, `obtener_totales_votacion`) aplicada en desarrollo y verificada con SQL revertido; 97 tests. En Android (2026-10-25): cuenta 1 (participante) votó, cambió su selección y el recuento usó la última; cuenta 2 vio los totales sin nombres, votó en «Prueba hora» (máximo 2 bloquea el tercero) y en «Prueba Yanahuara» (máximo ajustado a 2 candidatos). Vista del participante en el detalle revisada. Commit `2b3aeeb` (push por los usuarios)._
- [x] (B+A, 2 h) Cerrar votación (rechazo con 0 candidatos / 0 votos), resultado y desempate — RF08 · P05. _Migración `cerrar_votacion` (tabla `actividades_itinerario`, `cerrar_votacion`, `resolver_empate`) aplicada en desarrollo y verificada con SQL revertido (incluye rechazos sin candidatos y sin votos); 107 tests. En Android (2026-10-25): cuenta 2 cerró «Prueba hora» (`TIXJFG`) con empate en el 2.º puesto, cuenta 1 vio el resultado y el aviso sin poder desempatar, y cuenta 2 eligió Chaqchao Express (servidor: BAWi posición 1, Chaqchao 2). El rechazo sin votos no se probó en Android (solo SQL y tests)._

## Semana 3 (2026-11-04 → 11-12) · Itinerario, asistencia, avisos y entrega · ~18 h

Entregable: **MVP feature complete** — recorrido completo de creación a salida confirmada con asistencia, reemplazo, cancelación y avisos locales; APK instalable el 2026-11-12.

**Estado (2026-11-11): feature complete.** Todas las tareas terminadas y probadas en Android; etiqueta `semana-3` (`d0bfc5d`) desplegada en `quedamos-demo` con las 13 migraciones y APK de release en `../entregas/quedamos-semana3.apk`. Solo falta que los usuarios la instalen en un teléfono distinto. Las notas «solo en desarrollo» de cada tarea quedaron superadas por ese despliegue.

- [x] (B+A, 3 h) Revisar itinerario: orden manual, fecha/hora, estimación de presupuesto (incompleta / excede), confirmar — RF08, RF12, RF09 · P08.
- [x] (A, 2 h) Plan acordado: resumen, código, horario de actividad vs atención — RF09 · P06. _Fecha de inicio, «Presupuesto acordado», dirección, compartir con hoja nativa; probado en Android con ambas cuentas (2026-11-09)._
- [x] (B+A, 2 h) Asistencia (solo asistiré / no asistiré), estados del grupo, fecha límite opcional con indicador «Plazo vencido» no bloqueante — RF16 · P06, P12. _RPC `responder_asistencia` (migración solo en desarrollo), «Tu asistencia», conteos, barra y chips, plazo desde Gestión; probado en Android con ambas cuentas (2026-11-09). «Plazo vencido» solo en tests._
- [x] (B+A, 2 h) Reemplazo directo de actividad y cancelación del plan, con historial — RF10 · P07, P06. _(2026-11-10: migración `20261110120000` solo en desarrollo; 156 tests; probado en Android: reemplazo y horario en `TIXJFG`, vista de la cuenta 1 y cancelación de «prueba-c»)_
- [x] (B, 2 h) `notificaciones` + `sincronizar_notificaciones_plan` (voto y asistencia solo si hay fecha límite; actividad, cambio y cancelación según asistencia) — RF14. _(2026-11-10: migración `20261110150000_notificaciones` con triggers, solo en desarrollo, probada con transacción revertida)_
- [x] (A, 3 h) Avisos locales: permisos, sincronización al abrir/volver/deslizar, `zonedSchedule`/`cancel`, avisos inmediatos de cambio/cancelación, pestaña Notificaciones con nombre del plan y apertura de contexto — RF14 · P10. _(2026-11-10: 171 tests; probado en Android: permiso denegado y concedido, alarmas exactas de `TIXJFG`, recordatorio real de asistencia en `TWOMOY` que sonó, abrió el plan y quedó leído en el historial)_
- [x] (A+B, 2 h) Recorrido completo con ≥ 3 cuentas y 2 planes activos (administrador que también propone y vota). _(2026-11-10: en el emulador con 3 cuentas, R1 `JPXAJE` confirmado y R2 `8WU6H3` cancelado; sin errores; §12 orientativo 19 min 44 s)_
- [ ] (A, 1 h) APK de release instalable en un teléfono distinto al de desarrollo. _(2026-11-10: release corregida y verificada en el emulador contra desarrollo; APK final de la demo en `../entregas/quedamos-semana3.apk`; falta instalarla en otro teléfono)_
- [x] (B, 1 h) README de ejecución (sin secretos), cuentas y datos de demo, guion de presentación; comprobar que Supabase no esté pausado. _(2026-11-10: README reescrito; cuentas sin contraseñas, checklist y guion en `docs/07_PRESENTACION.md`)_

## Semana 4 (2026-11-13 → 11-19) · Estabilización (colchón) · ~14 h

Sin funciones nuevas. Si el MVP se entrega el 11-12, esta semana sirve para la versión mejorada del 11-19.

- [ ] (A+B, 3 h) Pruebas de usuario con personas del segmento y medición de `06_REQUIREMENTS.md` §12.
- [ ] (A+B, 3 h) Matriz de pruebas de RF14 (casos de `06_REQUIREMENTS.md` RF14 · Verificación), con app cerrada y tras reiniciar el teléfono.
- [ ] (A+B, 2 h) Fallos de red y permisos: sin éxitos falsos, sin duplicados, reintento, cuenta ajena sin acceso — RNF02, RNF03, RNF05.
- [ ] (A+B, 4 h) Corrección de bugs priorizados.
- [ ] (A, 2 h) Pulido visual frente a Figma.

---

## Si el tiempo no alcanza antes del 2026-11-12

Con 14 h/semana las semanas 1–3 no tienen holgura; la semana 4 absorbe retrasos solo si la entrega final es el 11-19. Orden de simplificación (consultar a los usuarios antes de aplicar cualquiera):
1. Pulido visual, animaciones e imágenes del catálogo (las tarjetas pueden ir sin foto).
2. Catálogo en el mínimo de 20 lugares.
3. Recomendaciones como filtro simple dentro de Explorar (sin pantalla propia).
4. Participantes y asistencia en la misma vista que el plan acordado (P12 dentro de P06).

**No retirar** itinerario, recomendaciones, asistencia ni notificaciones sin consultar a los usuarios.
