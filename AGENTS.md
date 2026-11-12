# AGENTS.md — Quedamos MVP

Guía obligatoria para cualquier agente de IA que trabaje en este repositorio.
Este archivo y la carpeta `docs/` se **versionan** como memoria compartida entre agentes y computadoras
(decisión 2026-11-11); el repositorio es **público**, así que nunca llevan secretos, correos ni contraseñas.
Solo `docs/07_PRESENTACION.md` queda local (ignorado).

## 1. Producto

**Quedamos** es una app móvil para organizar salidas grupales en **Arequipa**. Un grupo de amigos crea un plan,
se une con un código, propone lugares del catálogo, vota (varios lugares por persona, totales sin identificar
votantes), y los administradores cierran la votación, desempatan, ordenan el itinerario con fecha/hora y lo
confirman. Cada participante responde asistencia para toda la salida y recibe avisos automáticos
(30 min antes de cada actividad, cambios/cancelación y un recordatorio 1 h antes de los plazos de voto y asistencia).

- Problema validado en 30 entrevistas: los grupos grandes que deciden entre varios tardan cerca de una hora,
  la información de los lugares (ubicación, horario, precio) está dispersa y cuesta cambiar de plan.
- Propuesta de valor: decidir rápido, información confiable y cambio de plan sencillo.
- Navegación: 4 pestañas — **Mis salidas**, **Explorar lugares**, **Notificaciones**, **Perfil**.
- Decisiones recientes clave: Crear plan pide solo nombre, presupuesto y límites precargados
  (propuestas/persona 3, candidatos 6, selecciones 3, actividades 3); el **código** (6 caracteres) aparece
  después de crear; al proponer se elige el plan destino; estados fijos y unidireccionales
  (`recibiendo_propuestas` → `en_votacion` → `preparando_itinerario` → `confirmado` / `cancelado`).
- Especificación completa: `docs/06_REQUIREMENTS.md` (RF01–RF18, RB01–RB19, RNF01–RNF08, P01–P12).

## 2. Stack, plataformas y plazo

| Capa | Tecnología (aprobada 2026-10-21) |
|---|---|
| Frontend | Flutter (Dart), Material 3, `go_router`, `ChangeNotifier` + `provider` |
| Backend | Supabase: Auth (correo/contraseña, «Confirm email» desactivado), Storage |
| Base de datos | PostgreSQL con RLS y funciones RPC `security definer` |
| Avisos | Tabla `notificaciones` + `flutter_local_notifications` (avisos locales). **Sin FCM, sin Edge Functions ni Cron** en la primera iteración |

- **Multiplataforma desde el día 1:** el código Dart y los paquetes de `pubspec.yaml` deben ser 100 %
  compatibles con **Android e iOS**. Prohibido usar paquetes, permisos o diseños exclusivos de una sola
  plataforma. Cada permiso nativo se configura a la vez en `AndroidManifest.xml` y en `Info.plist`.
- **Todas las pruebas y compilaciones se hacen en Android** (no hay Mac; iOS no se compila en el MVP).
- **Plazo:** MVP **feature complete el 2026-11-12**; semana de colchón (solo pruebas, bugs y pulido) hasta el
  2026-11-19. Máx. 7 h/semana por integrante. Identificador de la app: `com.quedamos.app`. Priorizar siempre la solución más simple que cumpla los requisitos. No añadir funciones
  fuera de `docs/06_REQUIREMENTS.md`.
- Fuera de alcance: recuperación de contraseña, verificación de correo, SMTP, acceso con Google, push remoto.
- Presupuesto de servicios: costo cero (planes gratuitos).

## 3. Reglas de código

### 3.1 Convención de nombres
- `camelCase` para variables, funciones, métodos, parámetros y propiedades.
- `PascalCase` para clases, enums, widgets, extensiones y typedefs (estándar de Dart).
- `snake_case` para nombres de archivos y carpetas en Flutter (`plan_detail_screen.dart`)
  y para archivos e identificadores SQL (tablas, columnas, funciones) en Supabase.
- Las columnas `snake_case` se mapean a propiedades `camelCase` en `fromJson`/`toJson`.

### 3.2 Formato de comentarios en código (estricto)
- Todo comentario se escribe **en minúsculas**.
- **Sin emojis**, sin signos de admiración (`!`) ni de interrogación (`?`) dentro del comentario.
- Nunca dirigirse a los usuarios ni al lector: sin segunda persona, sin notas conversacionales,
  sin «ojo», «recuerda», «aquí puedes». Los comentarios describen qué hace el código o por qué.
- Correcto: `// reemplaza la seleccion completa para contar solo la ultima version guardada`
- Incorrecto: `// ¡Ojo! Aquí debes cambiar esto si quieres más votos?`
- Aplica a Dart, SQL, TypeScript, YAML y Gradle/Plist.

### 3.3 Estilo general
- Respetar `flutter analyze` sin advertencias y `dart format`.
- Ninguna pantalla habla directamente con Supabase: Screen → ViewModel → Repository.
- Toda escritura con reglas de negocio se hace por RPC (ver `docs/04_DATABASE_SCHEMA.md` §6).
- Nunca mostrar éxito antes de la confirmación del servidor; manejar estados de carga, vacío, error.
- No inventar datos de lugares (precio/horario desconocido se muestra como desconocido).

## 4. Seguridad

- **Jamás** exponer claves API, URLs sensibles, tokens ni secretos en el código fuente, commits,
  logs, comentarios o documentación versionada.
- La configuración de la app se lee con `String.fromEnvironment` y se ejecuta con
  `flutter run --dart-define-from-file=.env.json`. `env.example.json` lleva solo claves vacías.
- La `service_role` key de Supabase y la contraseña de la base de datos nunca entran en la app ni en el
  repositorio. Si en el futuro se añade FCM, sus archivos (`google-services.json`, `GoogleService-Info.plist`,
  `firebase_options.dart`) tampoco se versionan.
- RLS activo en todas las tablas; los votos individuales solo son legibles por su autor.

## 5. Git y `.gitignore`

- Todo `Quedamos_mvp` se versiona en un repositorio remoto **público**, incluidos `AGENTS.md` y `docs/`, **excepto**
  `docs/07_PRESENTACION.md`, `design_ref/` y cualquier `.env*` o archivo con credenciales. No modificar esas reglas
  del `.gitignore` sin decisión de los usuarios (en Windows git ignora mayúsculas: una regla `/Docs/` ocultaría `docs/`).
- Antes de cada commit, verificar con `git status` que no aparecen `.env*`, `07_PRESENTACION.md` ni secretos.
- **Sincronización entre computadoras:** `git pull` antes de empezar una sesión (los agentes leen `docs/` actualizado);
  los cambios de `docs/` van en el **mismo commit** que el código que describen; push al terminar la sesión.
  Si hay conflicto en `docs/01_STATE.md`, conservar las líneas de ambos y rehacer el resumen.
- Commits pequeños y descriptivos en español; no hacer commit ni push sin que los usuarios lo pidan.

## 6. Figma vs requisitos (jerarquía)

- Los mockups de Figma (vía MCP o capturas) son **referencia visual y de estructura de UI**.
- No están 100 % alineados con las pantallas P01–P12. **Ante cualquier discrepancia entre un mockup y
  `docs/06_REQUIREMENTS.md`, detenerse y consultar a los usuarios** si prevalecen las reglas de
  `06_REQUIREMENTS.md` o si estas deben modificarse para adecuarse al mockup.
- Registrar la respuesta en `docs/03_DECISIONS.md` y, si cambia una regla, actualizar `06_REQUIREMENTS.md`.
- Discrepancias ya conocidas (Google login, WhatsApp, 6/3/3 en Crear plan, etc.): `docs/05_ARCHITECTURE.md` §8.

## 7. Suposiciones

- Toda suposición no documentada en `docs/` o en la tarea actual se consulta con los usuarios.
- Los puntos marcados _Pendiente_ en `06_REQUIREMENTS.md` no se implementan por suposición: se
  implementa lo confirmado y se anota la duda en `docs/01_STATE.md` › Bloqueos.

## 8. Protocolo de memoria y handoff (obligatorio)

### 8.1 Al iniciar sesión
Primero `git pull`. En una computadora nueva, completar su fila en `docs/01_STATE.md` › Entornos por computadora.

| Siempre | Leer `docs/01_STATE.md` (estado vivo, siguiente paso, bloqueos). |
|---|---|
| Antes de implementar una pantalla o lógica de negocio | Leer `docs/06_REQUIREMENTS.md` (RF, RB y ficha P correspondientes). |
| Antes de tocar consultas, tablas, migraciones, RLS o RPC | Leer `docs/04_DATABASE_SCHEMA.md`. |
| Antes de crear componentes, rutas o dependencias en Flutter | Leer `docs/05_ARCHITECTURE.md`. |
| Al planificar o elegir la siguiente tarea | Leer `docs/02_ROADMAP.md`. |
| Ante una duda de «por qué se hizo así» | Leer `docs/03_DECISIONS.md`. |

### 8.2 Al finalizar sesión
1. `docs/01_STATE.md` (siempre):
   - Actualizar _En progreso ahora_ y _Siguiente paso inmediato_.
   - Añadir o resolver _Bloqueos/Dudas_.
   - Añadir una línea al inicio de _Últimas 3 sesiones_ (fecha · qué se hizo · qué quedó).
     Mantener solo las 3 más recientes y como máximo 15 líneas; borrar lo antiguo.
2. `docs/02_ROADMAP.md`: marcar `[x]` las tareas terminadas según su regla de avance.
3. `docs/03_DECISIONS.md`: añadir toda decisión nueva (`Fecha | Decisión | Motivo`).
4. `docs/04_DATABASE_SCHEMA.md`: actualizar si cambió una tabla, política o RPC (y crear la migración).
5. `docs/05_ARCHITECTURE.md`: actualizar si cambió estructura, dependencia o configuración nativa.
6. `docs/06_REQUIREMENTS.md`: actualizar solo con aprobación explícita de los usuarios.

### 8.3 Reglas de la memoria
- No duplicar contenido entre archivos: enlazar al documento fuente.
- Este `AGENTS.md` debe mantenerse por debajo de 200 líneas.
- Los documentos de `FormatoEntrevista/` son historia: no se usan como instrucción si contradicen `docs/`.

## 9. Mapa de documentos

| Archivo | Contenido |
|---|---|
| `docs/01_STATE.md` | Estado vivo, checklist inmediato, bloqueos, últimas 3 sesiones |
| `docs/02_ROADMAP.md` | Plan de 3–4 semanas con horas y checkboxes vinculados a RF y P |
| `docs/03_DECISIONS.md` | Decisiones vigentes de negocio y técnicas |
| `docs/04_DATABASE_SCHEMA.md` | Tablas, relaciones, RLS, RPC y automatización de avisos |
| `docs/05_ARCHITECTURE.md` | Carpetas Flutter, multiplataforma, estado, entorno, contratos, Figma → widgets |
| `docs/06_REQUIREMENTS.md` | Especificación funcional consolidada (fuente de verdad funcional) |
| `docs/07_PRESENTACION.md` | Cuentas de demo, checklist y guion (**solo local**, no está en git; existe en la computadora de Alexis) |

## 10. Reglas operativas vigentes (dadas por los usuarios)

- **Migraciones:** solo agregan objetos; se aplican únicamente en desarrollo con `npx supabase db push --linked`
  desde `Quedamos_mvp`. Nunca tocar `../Quedamos_demo` ni `quedamos-demo` salvo en el procedimiento semanal que pidan
  los usuarios (`docs/05_ARCHITECTURE.md` §6), verificando antes que el destino sea el proyecto correcto.
- **Procedimiento semanal con un solo responsable:** solo la computadora de **Alexis** (la única con `../Quedamos_demo`
  enlazado a `quedamos-demo`) aplica migraciones a la demo y compila la APK de entrega. En cualquier otra computadora
  el agente no enlaza ni toca la demo; si hace falta, lo anota en `docs/01_STATE.md` para que lo haga el responsable.
  Cambiar de responsable es una decisión de los usuarios (registrarla en `docs/03_DECISIONS.md`).
- **Acciones irreversibles** (confirmar o cancelar planes, cerrar votaciones, reemplazar actividades, cambiar datos de
  planes existentes): solo con autorización explícita y para el plan que indiquen los usuarios; para probarlas, pedir un plan nuevo.
- **Cuentas:** el agente no crea cuentas, no escribe contraseñas ni inicia sesión; si hace falta cambiar de cuenta
  o crear un plan de prueba, lo hacen los usuarios. Nunca leer, mostrar ni escribir claves (`.env.json`).
- **Pruebas:** en el emulador Android de cada computadora (el de Alexis es `emulator-5554`), ejecutando con `--dart-define-from-file=.env.json`. Código compatible con Android e iOS.
- **UI:** todo botón dentro de un `Row` lleva `minimumSize: Size(0, 44)` (decisión 2026-11-09). Cada pantalla nueva
  tiene un test de widget con `AppTheme.claro`. Antes de entregar: `flutter analyze` sin avisos y `flutter test` en verde.
- **Git:** el agente no hace commit ni push; entrega el comando `git add …` y `git commit -m "…"` en español, **sin línea
  Co-Authored-By**, tras revisar `git status`. Las etiquetas `semana-N` las crean y suben los usuarios.
- **Cada tarea termina** probada en Android y con `docs/` actualizado según §8.2.
