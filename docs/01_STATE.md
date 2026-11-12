# 01 · Estado del proyecto

Actualizado: 2026-11-11 · Leer completo al iniciar sesión (≈ 5 min). Las reglas de trabajo están en `AGENTS.md` §10.

## Resumen en 30 segundos

- **Alcance funcional completo** (RF01–RF18, P01–P12) implementado, conectado al servidor y probado en Android.
  Último commit de código: `d0bfc5d` (= etiqueta `semana-3` = `origin/main`). Árbol de trabajo limpio. 173 tests, `flutter analyze` sin avisos.
- **Fase actual: semana 4 de estabilización** (2026-11-13 → 2026-11-19): sin funciones nuevas; solo pruebas, bugs y pulido
  (`02_ROADMAP.md` › Semana 4). Hito: MVP feature complete el 2026-11-12 (cumplido el 2026-11-10).
- **Demo actualizada** a `semana-3`: `quedamos-demo` tiene las 13 migraciones y el seed; APK de release en
  `../entregas/quedamos-semana3.apk` (pasa del splash; inicio de sesión contra la demo aún sin probar).

## Qué hay implementado (mapa rápido)

| Área | Pantallas / RF | Dónde (código) | Migración |
|---|---|---|---|
| Acceso y perfil | P11, RF15; Perfil | `features/auth`, `features/perfil` | `20261022120000` |
| Mis salidas, crear, unirse, administradores, límites | P01, P02, P12 · RF01, RF02, RF17, RF18 | `features/salidas` | `20261022140000`–`20261023140000` |
| Catálogo, ficha, proponer, recomendaciones | P03, P04, P09 · RF03–RF05, RF11, RF13 | `features/lugares` | `20261024120000`, `20261025120000` |
| Preparar, votar, cerrar, desempatar | P05 · RF06, RF07, RF08 | `features/votacion` | `20261025140000`–`20261025180000` |
| Itinerario, presupuesto, confirmar | P08 · RF08, RF12 | `features/itinerario` | `20261109120000` |
| Plan acordado, compartir, asistencia | P06, P12 · RF09, RF16 | `features/salidas` | `20261109150000` |
| Reemplazo, horario, cancelación, historial | P07, P06 · RF10 | `features/itinerario` | `20261110120000` |
| Avisos (servidor + locales) | P10 · RF14 | `features/notificaciones` | `20261110150000` |

Contratos de cada repositorio en `05_ARCHITECTURE.md` §7; tablas, RLS y RPC en `04_DATABASE_SCHEMA.md`.

## Entornos y datos

| Entorno | Carpeta | Supabase | Estado |
|---|---|---|---|
| Desarrollo | `Quedamos_mvp` (rama `main`) | proyecto `ycon…` | 13 migraciones; aquí se aplican las nuevas con `npx supabase db push --linked` |
| Demo | `../Quedamos_demo` (worktree en HEAD separado sobre `semana-3`) | `quedamos-demo` (`qdcq…`) | 13 migraciones + seed (2026-11-10); solo se toca en el procedimiento semanal que pidan los usuarios (`05_ARCHITECTURE.md` §6) |

- **Emulador de Alexis** `emulator-5554` (Pixel 7, API 35): tiene la APK de release de la **demo**, sin sesión. Para volver a
  desarrollo: `adb uninstall com.quedamos.app` y `flutter run --dart-define-from-file=.env.json`; los usuarios inician sesión.
- **Cuentas** (registradas por los usuarios; el agente nunca escribe contraseñas): cuenta 1 «Alexis editado»,
  cuenta 2 «Mónica prueba», cuenta 3 «Pedro prueba». Existen en desarrollo; en la demo hay que registrarlas (`07_PRESENTACION.md`).
- **Planes en desarrollo** (no cambiarlos sin permiso de los usuarios; para probar algo irreversible, pedir un plan nuevo):
  - `TIXJFG` «Prueba hora»: confirmado, sáb 14 nov (Capriccio 16:00, BAWi 19:00 Lima), 2 cambios en el historial; cuenta 2 admin «asistiré», cuenta 1 «no asistiré».
  - `TWOMOY` «Prueba Yanahuara»: `en_votacion` con un voto; ambas cuentas admin.
  - `JPXAJE` «Recorrido sabado» (R1): confirmado el 10 nov (actividades ya pasadas); `8WU6H3` «Recorrido domingo» (R2) y `OTKNF6` «prueba-c»: cancelados.
- **Planes en la demo**: «Prueba Yanahuara» y «Pruebita» (de semanas anteriores).
- Catálogo: 28 lugares de `supabase/catalogo_lugares.csv` (5 zonas, 4 categorías) en ambos proyectos.

## Siguiente paso inmediato (checklist)

- [ ] Usuarios: registrar o iniciar sesión con las 3 cuentas en la demo, comprobar que carguen Mis salidas y Explorar,
      e instalar `quedamos-semana3.apk` en un teléfono distinto (cierra la última tarea de la semana 3 en `02_ROADMAP.md`).
- [ ] Usuarios: completar los correos de las cuentas en `07_PRESENTACION.md` (sin contraseñas).
- [ ] Semana 4, en este orden sugerido: matriz de RF14 (app cerrada, tras reiniciar el teléfono) → fallos de red y permisos
      (RNF02, RNF03, RNF05) → pruebas de usuario y medición §12 → bugs priorizados → pulido frente a Figma.

## Bloqueos / Dudas pendientes con los usuarios

- Hallazgo conocido sin corregir (decisión 2026-11-10): con 2 o más notificaciones, Android las agrupa y tocar el grupo abre la
  app sin ir al plan (tocar una individual sí abre su plan).
- Discrepancias de mockups abiertas (consultar si se tocan): pantalla «Calificación» (no está en P01–P12) y botón «Votar» en las tarjetas de Mis salidas.
- Lo marcado _Pendiente_ en `06_REQUIREMENTS.md` (filtros extra, punto de reunión, duración y conflictos de horario,
  preferencias de avisos, push remoto) queda fuera del MVP salvo nueva decisión.
- No verificado en dispositivo (solo tests): avisos de exceso de presupuesto y de estimación incompleta en Revisar itinerario;
  máximo de 10 recomendaciones; aviso tras reiniciar el teléfono.

## Entornos por computadora

Cada agente trabaja con el código y `docs/` de `git pull`; lo que sigue depende de la computadora. Al empezar en una
computadora nueva, añadir o completar su fila (sin claves ni rutas con datos personales).

| Computadora | Flutter / emulador | Supabase CLI | Demo y entregas |
|---|---|---|---|
| Alexis (Windows) | `C:\src\flutter` 3.47.7, `emulator-5554` (Pixel 7, API 35) | `Quedamos_mvp` enlazado a desarrollo | `../Quedamos_demo` y `../entregas`; **responsable del procedimiento semanal** |
| Compañera (Codex) | _(completar)_ | _(completar: enlazar solo a desarrollo, nunca a la demo)_ | no aplica |

**Primer arranque en otra computadora:** pedir a Alexis por un canal privado los valores de `.env.json` (URL y clave
pública de **desarrollo**) y, si se quiere, una copia de `design_ref/` (mockups, no versionados); `flutter pub get`;
`npx supabase login` + `npx supabase link --project-ref <ref de desarrollo>` (requiere acceso al proyecto);
`flutter test`. Las cuentas de prueba existentes son de Alexis: la compañera puede registrar las suyas en desarrollo.

### Referencia rápida (computadora de Alexis)

- Flutter 3.47.7 en `C:\src\flutter` (en Git Bash: `export PATH="/c/src/flutter/bin:$PATH"`); NDK 28.2.13676358; adb en
  `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`. Si el emulador queda en negro: Cold Boot.
- Ejecutar: `flutter run --dart-define-from-file=.env.json`. Release: `flutter build apk --release --dart-define-from-file=.env.json`.
- `.env.json` (ignorado, uno por carpeta) con `SUPABASE_URL` y `SUPABASE_ANON_KEY`: nunca leer ni mostrar sus valores.
- Supabase CLI `npx supabase` 2.122.0 (sin Docker). Verificar con `npx supabase migration list --linked`; consultas con
  `npx supabase db query --linked`. Pruebas de RPC dentro de un bloque `do` que termina en `raise exception` (se revierte).
- Diseño: `design_ref/DESIGN.md` (tokens) y `design_ref/figma/*.png`; tema en `lib/app/theme/` (`AppTheme.claro`).
- Herramientas de prueba en Android: `adb shell dumpsys alarm | grep quedamos` (alarmas programadas),
  `adb shell dumpsys notification --noredact` (notificaciones mostradas), `adb exec-out screencap -p > captura.png`.

## Últimas 3 sesiones

- 2026-11-11 · `AGENTS.md` y `docs/` pasan a versionarse (repositorio público; `07_PRESENTACION.md` sigue local), reglas de sincronización y responsable único de la demo, entornos por computadora. Quedó: commit de los usuarios y primer arranque de la compañera con Codex.
- 2026-11-11 · Documentación reorganizada para traspaso: `01_STATE` resumido, reglas operativas en `AGENTS.md` §10, cabeceras de `04`/`05` al día. Quedó: semana 4.
- 2026-11-10 · Procedimiento semanal semana 3: 4 migraciones en `quedamos-demo` y APK de release en `../entregas/quedamos-semana3.apk` (pasa del splash). Quedó: probar con cuentas en la demo y en otro teléfono.
