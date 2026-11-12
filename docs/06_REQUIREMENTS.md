# 06 · Especificación funcional consolidada — Quedamos MVP

Versión 1.4 · 2026-11-09 · Fuente: `FormatoEntrevista/5_requisitos_aplicacion.md` v0.11, `5_tabla_requisitos_principales.md` y decisiones del `AGENTS.md` anterior (hasta 2026-10-04), actualizadas con las decisiones del 2026-10-21 (stack aprobado, Android + iOS, 4 semanas) y con la resolución de los 12 bloqueos del 2026-10-21 (v1.1: avisos locales sin push, sin recuperación de contraseña, catálogo fijo, estados definitivos, código, rangos de límites, cierre, reemplazo y administradores) y con los 6 detalles cerrados el 2026-10-22 (v1.2: propuestas únicas y retirables, recomendaciones, plazos opcionales, asistencia sin vuelta a pendiente y plazo no bloqueante) y con la nota de Perfil unificada el 2026-10-22 (v1.3: nombre visible editable) y con el formato del resumen compartido del 2026-11-09 (v1.4, RF09).

> **Jerarquía.** Este documento es la fuente de verdad funcional. Si un mockup de Figma contradice algo de aquí, **no se implementa ninguna de las dos versiones por iniciativa propia**: se consulta a los usuarios si prevalece este documento o si debe modificarse para adecuarse al mockup (ver `05_ARCHITECTURE.md` §8).
>
> **Pendientes.** Todo lo marcado como _Pendiente_ debe consultarse con los usuarios antes de implementar el comportamiento que dependa de ello. Mientras tanto se implementa lo confirmado. Ninguna alternativa se considera elegida por falta de respuesta.

---

## 1. Producto

**Quedamos** es una app móvil (Android + iOS) para que grupos de amigos de **Arequipa** decidan una salida rápido, consulten información confiable de los lugares (ubicación, horario, precio) y cambien de opción cuando el plan falla.

- **Problema.** Los grupos grandes que deciden entre varios tardan cerca de una hora en ponerse de acuerdo; la información de los lugares está dispersa o no es confiable; hay cancelaciones, sorpresas de precio y dificultad para reemplazar una actividad.
- **Usuarios iniciales.** Personas que salen con grupos grandes de amigos y coordinan entre varios. Parejas y grupos pequeños son segmento secundario.
- **Propuesta de valor.** Reducir el tiempo de decisión, dar información confiable de ubicación/horario/presupuesto y facilitar el cambio de plan sobre la marcha.
- **Fuera de alcance** (no implementar sin requisito aprobado): red social, seguidores, chat, pagos, reservas, transporte, publicidad, posicionamiento patrocinado, cuentas verificadas de negocios, integración con WhatsApp, generación automática de itinerarios o conversación con IA, acceso sin cuenta, acceso con Google, recuperación de contraseña, verificación de correo, push remoto (FCM), reapertura de votación, retiro de administradores, pantalla administrativa del catálogo.

## 2. Roles

Los roles son **por plan**; no otorgan permisos sobre otros planes ni sobre el catálogo general.

| Rol | Puede | Pendiente |
|---|---|---|
| Participante registrado | Unirse con código en cualquier fase activa, proponer lugares (eligiendo el plan destino), votar y modificar su selección hasta el cierre, responder asistencia para toda la salida, consultar respuestas del grupo. | Tratamiento ante cambios del plan y vencimiento del plazo de asistencia. |
| Administrador del plan | Todo lo del participante (también propone y vota) + elegir la lista final de candidatos, configurar límites antes de votar, fijar plazos de voto y asistencia, nombrar administradores, abrir y cerrar la votación, resolver empates, ordenar y asignar fecha/hora a actividades, confirmar, reemplazar actividades o cancelar el plan. El rol es **permanente** en ese plan (no hay retiro de administradores en el MVP). | — |
| Creador | Es el **primer administrador** del plan. **No puede abandonar el plan ni perder su rol**; solo puede cancelarlo. | — |
| Responsable del catálogo (equipo) | Cargar y revisar los lugares mediante `seed.sql` / dashboard de Supabase, con procedencia y fecha de revisión. | — |

## 3. Navegación principal: 4 pestañas

Barra inferior con cuatro pestañas (decisión 2026-10-01; etiquetas cortas del mockup aprobadas 2026-10-22: **Mis salidas · Explorar · Avisos · Perfil**):

| Pestaña | Contenido | Pantallas |
|---|---|---|
| **Mis salidas** | Lista de planes del usuario (puede haber varios activos), acceso a Crear plan y Unirse con código, detalle de cada plan con sus fases. | P01, P02, P05, P06, P07, P08, P12 |
| **Explorar lugares** (etiqueta «Explorar») | Catálogo de Arequipa, ficha, recomendaciones y acción de proponer **seleccionando explícitamente el plan destino**. | P03, P04, P09 |
| **Notificaciones** (etiqueta «Avisos») | Historial de avisos (tabla `notificaciones`), cada uno identificando el **nombre del plan**; abrir un aviso lleva al contexto. Estado del permiso de notificaciones del dispositivo. | P10 |
| **Perfil** | Nombre visible (editable), correo y cierre de sesión. | P11 (cierre de sesión) |

P11 (registro/acceso) se muestra fuera de las pestañas cuando no hay sesión.

## 4. Ciclo de vida del plan

**Estados definitivos (confirmados 2026-10-21):**

`recibiendo_propuestas` → `en_votacion` → `preparando_itinerario` → `confirmado`, y `cancelado` desde cualquiera de las anteriores.

- El flujo es **unidireccional**: no se retrocede de fase y **no existe reapertura de votación**. `cancelado` es final.
- Las propuestas solo se reciben en `recibiendo_propuestas`.
- La fase `preparando_itinerario` existe para el desempate, orden y asignación de horarios tras el cierre; el resultado de la votación **no** equivale a plan confirmado.
- Lista de candidatos y límites quedan fijos desde `en_votacion`.
- En `confirmado` el administrador aún puede reemplazar actividades o cambiar horarios (sin cambiar de fase).

## 5. Valores iniciales por plan (configurables)

| Límite | Valor inicial | Rango válido | Dónde se configura |
|---|---|---|---|
| Máximo de lugares propuestos por persona | **3** | 1 a 5 | Crear plan (P01); no se modifica después |
| Máximo de candidatos en la lista final | **6** | 2 a 10 | Crear plan (P01) y Preparar votación (P05) hasta abrir la votación |
| Máximo de selecciones por participante | **3** | 1 a 5, y ≤ máximo de candidatos | Crear plan (P01) y Preparar votación (P05) hasta abrir la votación |
| Máximo de actividades del itinerario | **3** | 1 a 5 | Crear plan (P01) y Preparar votación (P05) hasta abrir la votación |

Todos confirmados (2026-10-21). En Crear plan aparecen precargados y editables. Los valores iniciales **no** son límites fijos del sistema. El límite de propuestas por persona es distinto del máximo de candidatos finales.

---

## 6. Requisitos funcionales (RF01–RF18)

Cada criterio describe un resultado observable. Un criterio condicionado por una regla pendiente no se considera prueba completa hasta resolverla.

### RF01 Crear un espacio para decidir una salida

La persona que inicia la salida podrá crear un plan y acceder a un espacio compartido de decisión, y consultar sus salidas en _Mis salidas_.

**Reglas confirmadas.** El creador obtiene el rol de primer administrador. Los **únicos campos** de Crear plan son: `nombre` (obligatorio), `presupuesto_soles` por persona para toda la salida (obligatorio, solo actividades) y los límites precargados y editables de la sección 5 (propuestas por persona 3, candidatos 6, selecciones 3, actividades 3, dentro de sus rangos). No hay fecha/hora general ni zona en el plan. Crear plan es una **pantalla dedicada**, separada de _Mis salidas_. El **código de invitación se muestra después de crear** el plan, en su detalle, con confirmación breve y acción de copiar.

**Criterios de aceptación.**
- Al completar los campos obligatorios aprobados se crea un plan identificable.
- Si falta un campo obligatorio, se señala cuál y se conservan los datos ya ingresados.
- Un fallo de guardado muestra un mensaje y permite reintentar sin crear planes duplicados.
- Tras crear, se navega al detalle del plan, donde está disponible el código.
- El creador figura como administrador del plan.
- Un límite fuera de rango o con selecciones mayores que candidatos se señala y no se guarda.

La identidad del creador corresponde a su cuenta registrada.

### RF02 Invitar a participantes

El plan tendrá un código de invitación que sus amigos introducirán dentro de la app para unirse, después de registrarse o iniciar sesión.

**Reglas confirmadas.** Los participantes necesitan cuenta y se unen mediante código. No se requiere un enlace que abra directamente el plan. No hay integración con WhatsApp.
- **Formato:** 6 caracteres alfanuméricos en mayúsculas (ej. `AQP48X`), generado por el servidor y único. La entrada se normaliza a mayúsculas.
- **Vigencia:** no caduca por fecha; queda inactivo solo cuando el plan pasa a `cancelado`.
- **Fases:** se puede unir en cualquier fase activa (`recibiendo_propuestas`, `en_votacion`, `preparando_itinerario`, `confirmado`). Quien se une en `confirmado` va directo al itinerario y a responder asistencia.
- **Compartir:** acción _Copiar código_ (portapapeles).

**Criterios de aceptación.**
- Introducir un código válido después de iniciar sesión permite unirse al plan correspondiente.
- Un código inexistente o de un plan cancelado informa que no es válido y no incorpora al usuario a otro plan.
- Volver a usar el mismo código con una cuenta ya participante no duplica su participación.
- La persona conoce qué puede consultar y hacer antes de participar, según la fase del plan.

### RF03 Consultar opciones para la salida

El usuario podrá explorar los lugares de la cobertura aprobada (pestaña _Explorar lugares_). Búsqueda y filtros solo se incorporarán si el volumen del catálogo y el alcance lo justifican.

**Criterios de aceptación.**
- Cada opción permite consultar su información.
- Una consulta sin opciones muestra un estado vacío comprensible.
- Los filtros aprobados, si existen, permiten restablecer la consulta.

**Cobertura confirmada.** Arequipa, con catálogo inicial manual de **20–30 lugares reales** cargado por `seed.sql`.
- **Zonas fijas:** Centro Histórico, Yanahuara, Cayma, Vallecito, Cercado.
- **Categorías fijas:** Restaurantes, Cafés y Postres, Bares, Entretenimiento y Cultura.

Zona, presupuesto y categoría son las entradas de recomendaciones (RF13).

**Pendiente.** Búsqueda o filtros de exploración adicionales (no prioritarios con 20–30 lugares).

### RF04 Consultar información de un lugar

La ficha del lugar presentará ubicación, horario y precio o presupuesto orientativo cuando existan datos, diferenciando datos conocidos de información faltante.

**Criterios de aceptación.**
- Los datos disponibles son legibles antes de elegir.
- Un precio estimado no se presenta como precio garantizado.
- Los campos desconocidos se indican como tales y no se rellenan con valores inventados.
- El horario se describe sin asegurar disponibilidad o aforo si esa información no existe.

**Pendiente.** Unidad y componentes del precio, dirección, fuente, fecha de revisión, horarios especiales, representación del costo estimado por persona de cada actividad (en soles). Abrir una app de mapas externa es opción a evaluar.

### RF05 Agregar opciones a la decisión del grupo

Todos los participantes del plan podrán proponer lugares. Los administradores elegirán, entre las propuestas, la lista final de candidatos sobre la que se votará. Proponer no implica incorporar automáticamente a esa lista.

**Reglas confirmadas.** Al proponer se **selecciona explícitamente el plan destino** (el usuario puede tener varios planes activos; solo se listan los que están en `recibiendo_propuestas`). Cada persona puede proponer hasta el máximo configurado del plan (inicialmente 3, rango 1 a 5). Solo se proponen lugares del catálogo. Las propuestas solo se aceptan en `recibiendo_propuestas`; al abrir la votación ya no se reciben. El administrador también participa y puede proponer.
- **Sin duplicados:** un mismo lugar solo puede proponerse una vez por plan. Si ya lo propuso otro integrante, la UI lo muestra como «Ya propuesto» y no se puede volver a proponer; no consume el límite de nadie más que su autor.
- **Retiro:** el autor de una propuesta o un administrador puede eliminarla libremente, **solo** mientras el plan esté en `recibiendo_propuestas`. Retirarla libera el cupo del autor y, si el lugar ya estaba en la lista de candidatos, lo quita de ella.

**Criterios de aceptación.**
- Una propuesta agregada pertenece al plan elegido y puede ser revisada para definir los candidatos.
- No se puede superar el máximo de propuestas por persona del plan; se informa al alcanzarlo.
- Intentar proponer un lugar ya propuesto en ese plan no crea otra propuesta y se informa «Ya propuesto».
- El autor o un administrador puede retirar una propuesta en `recibiendo_propuestas`; en cualquier otra fase la acción no está disponible y el servidor la rechaza.
- La comparación conserva la información relevante de cada opción.
- Solo administradores pueden determinar la lista final; esta respeta el máximo configurado (inicialmente 6) y se fija antes de abrir la votación.
- Mientras se vota no puede añadirse, retirarse ni reemplazarse un candidato de esa lista.
- La votación solo acepta opciones de la lista final.
- Un error al agregar una propuesta no se muestra como operación exitosa.


### RF06 Registrar preferencias mediante votación

Cada participante podrá votar por varios lugares distintos de la lista de candidatos. Los lugares se comparan por cantidad de votos para incorporar los más votados al itinerario.

**Criterios de aceptación.**
- El sistema confirma la selección únicamente después de guardarla.
- La selección se vincula con la cuenta del participante y con el plan correcto.
- Cada lugar elegido cuenta una vez por participante y solo puede pertenecer a la lista final del plan.
- El máximo de lugares por persona es el configurado (inicialmente 3); se aplica al guardar (servidor) y en la interfaz.
- Mientras la votación esté abierta, la persona puede guardar una selección diferente: el recuento usa su **última selección guardada**, sin sumar versiones anteriores.
- Una selección enviada después del cierre no modifica el resultado.
- Si falla el envío, se permite reintentar sin duplicar votos.

**Visibilidad confirmada.** Todos los participantes consultan los totales por lugar durante la votación. La interfaz no muestra quién votó por cada candidato. La selección propia se muestra a su titular y permanece vinculada a su cuenta para modificarla y controlar duplicados. No se ordenan preferencias ni se asignan pesos.

### RF07 Mostrar el estado de la decisión

El grupo distinguirá si la decisión sigue abierta y consultará el total de votos por lugar, sin identificar votantes.

**Criterios de aceptación.**
- El estado mostrado coincide con el estado guardado.
- Se muestran totales por lugar durante la votación y se indica que todavía no son definitivos.
- No se presentan nombres ni listas de votantes asociados con los lugares.
- Cambiar una selección actualiza los totales usando la última selección guardada.
- Si hay un problema de actualización, no se presenta como información actualizada con éxito.

**Pendiente.** Forma y frecuencia de actualización (la visibilidad de totales no obliga a usar tiempo real; para el MVP basta recarga al abrir y al deslizar).

### RF08 Cerrar la decisión y confirmar el plan

Los administradores cerrarán la votación, resolverán empates y confirmarán el plan. El resultado ordenado por votos sirve para construir el itinerario; su orden de ejecución es manual.

**Criterios de aceptación.**
- Tras el cierre se muestra el resultado ordenado por cantidad de votos.
- Se incorporan al itinerario los lugares más votados hasta el máximo de actividades configurado (inicialmente 3).
- Un empate que afecte la selección puede ser resuelto por un administrador y su resolución guardada se refleja en el resultado.
- No se aceptan votos fuera del estado permitido.
- Solo administradores pueden cerrar, resolver empates o confirmar.
- El plazo de voto **no** cierra automáticamente la votación.

**Reglas de cierre confirmadas.**
- No se puede cerrar si hay **0 candidatos** o **0 votos emitidos en total**; se informa el motivo y la votación sigue abierta.
- Pasan al itinerario los candidatos con al menos un voto, ordenados por votos, hasta el máximo de actividades. Si hay menos candidatos votados que el máximo, se incorporan **todos los candidatos votados disponibles**. Los candidatos sin votos no pasan.
- Si un empate afecta al último puesto disponible, el administrador elige entre los empatados.
- **No existe reapertura** de la votación.

### RF09 Consultar y compartir el plan acordado

El grupo consultará un resumen de la salida con las actividades acordadas, su orden manual y los datos de coordinación definidos.

**Criterios de aceptación.**
- El resumen corresponde al plan confirmado.
- Incluye orden de actividades, fecha y hora asignadas por administradores y datos disponibles de ubicación, horario de atención y precio, sin convertir estimaciones en garantías.
- Distingue el horario de la actividad del horario de atención del lugar.
- Muestra el presupuesto por persona para toda la salida y la estimación de costo disponible del itinerario.
- Si falta el precio de una actividad, identifica que la estimación es incompleta.
- El contenido compartido identifica el plan y su código, sin dar por implementado un enlace de acceso.

**Formato del resumen compartido (confirmado 2026-11-09).** Texto plano enviado con la hoja nativa de compartir: nombre del plan, código, actividades en orden con fecha/hora, lugar y dirección, y presupuesto por persona con la estimación; sin enlace de acceso.

**Pendiente.** Punto de reunión y recuperación posterior.

### RF10 Cambiar o cancelar el plan

Los administradores podrán cambiar una actividad acordada mediante un flujo sencillo o cancelar el plan, comunicando su estado y gestionando los avisos afectados.

**Criterios de aceptación.**
- El usuario identifica que está cambiando un plan existente.
- Un cambio confirmado actualiza el resumen y se distingue de una propuesta todavía no aceptada.
- Un error conserva el último plan confirmado.
- Una cancelación guardada se refleja en el estado de la salida; los avisos asociados siguen RF14.
- Solo administradores cambian o cancelan.

**Reglas confirmadas.**
- El **reemplazo** lo decide y aplica directamente un administrador, **sin nueva votación**. La alternativa se elige entre los candidatos de la votación no elegidos (con su total de votos) o del catálogo filtrado por zona y categoría (confirmado 2026-11-10); no puede repetir un lugar del itinerario. La actividad conserva su posición y fecha/hora; no se recalculan horarios (el administrador puede editarlos después).
- Cada cambio (reemplazo, horario, cancelación) queda en un historial del plan.
- Los avisos de cambio y cancelación se dirigen a participantes con asistencia `pendiente` o `asistire` (se excluye `no_asistire`), según RF14.
- Al cancelar, el plan pasa a `cancelado`, su código queda inactivo y se anulan los recordatorios futuros.

### RF11 Mantener la información del catálogo

El responsable del catálogo tendrá un procedimiento definido para incorporar y revisar lugares.

**Criterios de aceptación.**
- Se conoce la procedencia de los datos utilizados.
- Una revisión deja registro de su fecha.
- La información incompleta o desactualizada sigue una regla explícita de publicación.
- Solo quien tiene permiso puede cambiar los datos mantenidos por el equipo.

**Procedimiento confirmado.** Catálogo manual de 20–30 lugares reales de Arequipa en `supabase/seed.sql`, con las zonas y categorías fijas de RF03. Cada registro guarda `fuente` y `fecha_revision`; datos sin verificar (precio, horario) se dejan vacíos y la app los muestra como desconocidos. Solo el equipo modifica el catálogo (SQL o dashboard de Supabase); no hay pantalla administrativa en la app. Sin integraciones externas (Google Places, etc.).

**Pendiente.** Frecuencia de revisión tras el MVP.

### RF12 Construir y consultar un itinerario

La salida incluirá varias actividades en orden identificable, hasta el máximo configurado (inicialmente 3). Se incorporan los lugares más votados; los administradores ordenan manualmente, asignan fecha y hora a cada actividad y confirman. No hay generación automática de itinerario ni conversación con IA.

**Criterios de aceptación.**
- El itinerario muestra qué actividad corresponde a cada posición, con fecha y hora asignadas por un administrador.
- Los participantes sin ese rol consultan los horarios y no pueden modificarlos.
- Los cambios guardados en actividades, orden, fecha u hora se reflejan al volver a consultar el plan.
- La interfaz distingue actividades no confirmadas y señala las que aún no tienen fecha/hora.
- Duraciones y conflictos temporales seguirán la regla que se defina.

**Presupuesto del itinerario (confirmado).** Soles (PEN) por persona para toda la salida; solo actividades, transporte aparte. Se suman las estimaciones disponibles por persona de las actividades. Los componentes sin precio se señalan como estimación incompleta. Si la suma supera el presupuesto, se muestra advertencia con presupuesto y estimación, y **un administrador puede confirmar igualmente**; el exceso no impide la confirmación.

**Zona horaria.** Todas las fechas se muestran y programan en `America/Lima`.

**Pendiente.** Duración, traslados y validación de conflictos temporales (en el MVP no se bloquean conflictos). Los cambios después de confirmar siguen RF10.

### RF13 Recomendar opciones automáticamente

La app sugerirá lugares de Arequipa según zona, presupuesto por persona y categoría, para incorporarlos a la decisión grupal. No requiere contratar un modelo de IA (filtros sobre el catálogo).

**Criterios de aceptación.**
- Las sugerencias corresponden a los datos y restricciones definidos.
- El usuario puede consultar la información de cada opción antes de proponerla.
- Si no hay opciones compatibles, se informa y no se inventan negocios, horarios ni precios.
- La recomendación no se considera acuerdo del grupo hasta completar la confirmación.

**Entradas.** Zona (una de las 5 fijas), categoría (una de las 4 fijas) y presupuesto en soles por persona, sobre el catálogo de RF11.

**Regla confirmada (2026-10-22).** Las tres entradas son obligatorias. Se filtra por `zona`, `categoria` y precio estimado por persona `<= presupuesto_soles`, se ordena por precio estimado ascendente (de más económico a más caro) y se muestran **como máximo 10** sugerencias. Los lugares con precio desconocido no aparecen en recomendaciones (sí en Explorar). Cada lugar se compara contra el presupuesto completo; no se reparte entre actividades, por lo que la suma del itinerario puede superarlo (RF12 advierte).

### RF14 Recibir recordatorios del plan

Los participantes recibirán avisos automáticos: 30 minutos antes de cada actividad, al cambiar o cancelar el plan y para recordar votar o responder asistencia. Nadie pulsa un botón para enviarlos. Cada aviso identifica el **nombre del plan** y queda en el historial de la pestaña _Notificaciones_.

**Mecanismo del MVP (confirmado 2026-10-21).** Sin push remoto (sin FCM, sin Apple Developer, sin Edge Functions ni Cron en la primera iteración):
- El servidor mantiene la tabla `notificaciones` (una fila por destinatario y evento, con su momento previsto); las RPC la crean, actualizan o anulan al cambiar el plan.
- La app sincroniza esas filas (al iniciar sesión, abrir la app, volver a primer plano y deslizar para recargar) y programa **avisos locales** en el dispositivo con `flutter_local_notifications` (Android e iOS).
- Los avisos de cambio y cancelación se muestran como aviso local en cuanto el dispositivo sincroniza.

**Destinatarios confirmados.**
- Actividad, cambio y cancelación: participantes con asistencia `pendiente` o `asistire` (se excluye `no_asistire`).
- Voto: participantes que aún no guardaron elecciones mientras la votación sigue abierta.
- Asistencia: participantes con asistencia `pendiente`.

**Limitación aceptada.** Lo que haga otra persona (cambio de horario, reemplazo, cancelación, cierre de votación) llega al dispositivo cuando la app se abre o vuelve a primer plano; hasta entonces puede sonar un recordatorio con el dato anterior o no mostrarse el aviso de cambio. Las acciones propias (votar, responder asistencia) cancelan el recordatorio local al instante.

**Regla confirmada de voto y asistencia.** Los administradores definen una fecha/hora límite para votar y otra para responder asistencia. Se envía **un único recordatorio automático 1 hora antes de cada plazo**, solo a quienes sigan pendientes de esa acción:
- Voto pendiente = todavía no guardó elecciones.
- Asistencia pendiente = todavía no respondió _asistiré_ ni _no asistiré_ (ambas excluyen del recordatorio).
- Haber votado no excluye del recordatorio de asistencia, y viceversa.
- El plazo de voto no cierra la votación; el cierre es manual.

**Criterios de aceptación.**
- El aviso de actividad se programa 30 minutos antes de la fecha/hora vigente asignada por un administrador, cuando el plan está `confirmado`.
- Guardar un cambio o cancelación genera automáticamente el registro del aviso para los destinatarios definidos, y el dispositivo lo muestra al sincronizar.
- Para voto y asistencia se programa un solo aviso por acción y participante, 1 hora antes del plazo. Ambos plazos son **opcionales**: si el administrador no define uno, no se programa el recordatorio de esa acción.
- Quien ya guardó elecciones no recibe el aviso de voto; quien ya respondió asistiré o no asistiré no recibe el de asistencia (el recordatorio local se cancela al guardar).
- Si la votación ya se cerró, no se solicita votar (el aviso se anula al sincronizar).
- Responder _no asistiré_ anula los avisos de actividad de esa persona.
- Cambiar el horario o cancelar anula los avisos afectados y crea los nuevos; al sincronizar no se mantiene un recordatorio del horario anterior.
- Si el momento del recordatorio ya pasó (plazo con menos de 1 h o actividad con menos de 30 min), no se programa.
- Si el permiso de notificaciones está deshabilitado, la interfaz no presenta los avisos como habilitados.
- Abrir un aviso conduce al contexto correspondiente si el acceso sigue siendo válido.
- No se muestran duplicados.

**Verificación (en Android).** Probar avisos de actividad, cambio/cancelación y un solo aviso por acción pendiente con participantes: sin acciones completadas; con voto guardado y asistencia pendiente; con asistencia respondida y sin voto; con ambas completadas. Probar _asistiré_ y _no asistiré_ (este último sin avisos de actividad). Probar que un recordatorio programado se dispara con la app cerrada, que se reprograma tras reiniciar el teléfono, y que un cambio hecho por otro administrador se refleja al volver a abrir la app. Comprobar permisos, acceso al contexto y ausencia de duplicados.

**Pendiente.** Preferencias de avisos (no se implementan en el MVP). Push remoto (FCM) como mejora posterior.

### RF15 Registrarse e iniciar sesión

Cada participante deberá tener una cuenta con **correo y contraseña** (Supabase Auth) para participar.

**Reglas confirmadas (2026-10-21).**
- Campos obligatorios del registro: `nombre_visible`, `email` y `password`. El nombre visible se muestra al grupo y puede editarse en _Perfil_.
- En Supabase Auth se **desactiva «Confirm email»**: registro e inicio de sesión son inmediatos, sin correo de confirmación, sin SMTP externo y sin deep links.
- **Fuera del alcance del MVP:** recuperación/restablecimiento de contraseña y verificación de correo. Si un usuario de prueba olvida su clave, el equipo la gestiona manualmente desde el dashboard de Supabase.
- Contraseña: se aplica el mínimo configurado en Supabase Auth (por defecto 6 caracteres).

**Criterios de aceptación.**
- La persona puede crear una cuenta con nombre visible, correo y contraseña e iniciar sesión con correo y contraseña.
- Los datos obligatorios se validan antes de completar el registro (nombre no vacío, correo con formato válido, contraseña con la longitud mínima).
- Un correo ya registrado se informa como error, sin crear otra cuenta.
- Una operación fallida no se muestra como registro o acceso exitoso.
- La participación y los votos se asocian con la cuenta correcta.
- Se puede cerrar la sesión (desde _Perfil_).
- La sesión se restaura al reabrir la app.

**Nota sobre mockups.** Los mockups muestran acceso con Google y, posiblemente, «¿Olvidaste tu contraseña?»; **ninguno de los dos se implementa**. El método confirmado es solo correo y contraseña.

### RF16 Confirmar asistencia a la salida

El participante responderá su asistencia para **toda la salida**: _pendiente_, _asistiré_ o _no asistiré_. Podrá modificarla. Todos los participantes del plan ven los estados del grupo. Los administradores pueden fijar una fecha/hora límite (opcional); el recordatorio sigue RF14.

**Reglas confirmadas (2026-10-22).**
- `pendiente` es solo el valor inicial al unirse. En la UI únicamente se elige entre _asistiré_ y _no asistiré_ (se puede cambiar entre ambos); no se puede volver a _pendiente_.
- El plazo de asistencia es un **plazo no bloqueante** (*soft deadline*): dispara el recordatorio 1 h antes y, una vez vencido, muestra el indicador «Plazo vencido», pero **no impide** cambiar la respuesta (p. ej. avisar una cancelación de última hora).
- Un cambio o reemplazo en el plan no reinicia las respuestas (no existe vuelta a pendiente).

**Criterios de aceptación.**
- Antes de responder, la asistencia figura como pendiente.
- La persona puede registrar asistiré o no asistiré y modificar su respuesta; se confirma el cambio solo después de guardarlo.
- Todos los participantes del plan consultan el último estado guardado de cada integrante.
- Un fallo permite reintentar sin duplicar la participación ni presentar un cambio fallido como guardado.
- Las cuentas ajenas al plan no acceden a esas respuestas.
- El plazo, si existe, se muestra en el contexto de asistencia; vencido, aparece «Plazo vencido» y la respuesta sigue siendo editable.
- La UI no ofrece volver a pendiente y el servidor rechaza ese valor.
- El recordatorio se dirige solo a quienes sigan pendientes al enviar.

No hay confirmación por actividad.

### RF17 Gestionar administradores del plan

El creador es el primer administrador. Los administradores pueden nombrar a otros participantes como administradores y ejercer las facultades de la sección 2. El rol aplica solo a ese plan.

**Criterios de aceptación.**
- Al crear el plan se asigna al creador como administrador.
- Se admiten varios administradores por plan y se distinguen de los participantes.
- Un administrador puede nombrar a otro participante del mismo plan.
- Los participantes sin rol no pueden realizar acciones administrativas.
- Los permisos se comprueban al guardar (servidor), no solo en la interfaz.
- Una asignación fallida conserva los roles anteriores.

**Reglas confirmadas.** El creador no puede abandonar el plan ni perder su rol; solo puede cancelar el plan. Los administradores nombrados conservan el rol de forma permanente en ese plan. **No se implementa retiro de administradores** en el MVP, por lo que siempre existe al menos un administrador (el creador).

### RF18 Configurar los límites del plan

Los límites aparecen precargados y editables al crear el plan. Después, los administradores pueden ajustar candidatos, selecciones y actividades en _Preparar votación_ hasta abrir la votación. El máximo de propuestas por persona solo se fija al crear.

**Rangos confirmados.** Propuestas por persona 1–5 (por defecto 3); candidatos 2–10 (6); selecciones 1–5 (3) y siempre ≤ candidatos; actividades 1–5 (3).

**Criterios de aceptación.**
- Un plan nuevo presenta los valores iniciales.
- Antes de abrir la votación, un administrador puede guardar otros valores dentro de los rangos; un valor fuera de rango o selecciones mayores que candidatos se rechaza con un mensaje.
- Los límites guardados se muestran al consultar el plan y se aplican al definir candidatos, registrar votos y construir el itinerario.
- Mientras la votación esté abierta, los límites se muestran fijos y no pueden modificarse, ni siquiera por un administrador.
- Un participante sin rol de administrador no puede modificar los límites.
- Si falla el guardado, se conservan los valores vigentes.

No hay reapertura ni cambios de límites después de abrir la votación. Si la lista final tiene menos candidatos que el máximo de selecciones, cada persona puede elegir como máximo el número de candidatos existentes.

---

## 7. Reglas de negocio (RB01–RB19)

Estado: **Confirmada** (implementable tal cual) · **Parcial** (parte confirmada implementable + detalle pendiente) · **Pendiente**.

| ID | Estado | Regla confirmada | Pendiente de definir | RF |
|---|---|---|---|---|
| RB01 | Confirmada | Cuenta obligatoria con `nombre_visible`, correo y contraseña (Supabase Auth, «Confirm email» desactivado). Sin recuperación de contraseña ni verificación de correo en el MVP; claves olvidadas se gestionan en el dashboard. | — | RF01, RF02, RF06, RF15 |
| RB02 | Confirmada | Todos proponen (solo en `recibiendo_propuestas`, solo del catálogo, con plan destino explícito; un lugar una sola vez por plan; el autor o un admin puede retirarla solo en esa fase); administradores definen la lista final, configuran límites, nombran otros, cierran, resuelven empates, ordenan, confirman, reemplazan o cancelan. Propuestas por persona 1–5, por defecto 3. | — | RF01, RF05, RF08, RF10, RF17, RF18 |
| RB03 | Confirmada | Selecciones por persona 1–5 (por defecto 3, ≤ candidatos), configurable antes de abrir la votación; cada participante cambia su selección hasta el cierre; cuenta la última guardada. | — | RF06, RF18 |
| RB04 | Confirmada | Totales por lugar visibles durante la votación; no se identifica quién votó por cada candidato; cada participante consulta su propia selección. | — | RF06, RF07 |
| RB05 | Confirmada | Cierre manual por administradores; el plazo de voto no cierra automáticamente. No se puede cerrar con 0 candidatos o 0 votos en total. Sin reapertura. | — | RF07, RF08, RF14 |
| RB06 | Confirmada | Los administradores resuelven empates en el último puesto. Pasan al itinerario los candidatos con votos hasta el máximo de actividades; si hay menos, todos los votados disponibles. | — | RF08 |
| RB07 | Confirmada | La lista final no puede modificarse desde que se abre la votación (no añadir, retirar ni reemplazar). No se reciben propuestas nuevas durante la votación. | — | RF05, RF06, RF08 |
| RB08 | Parcial | Presupuesto en soles por persona para toda la salida, solo actividades, transporte aparte; ante exceso, advertencia y confirmación permitida a administradores; falta de precio = estimación incompleta. | Cómo estimar el gasto por persona cuando faltan precios. | RF01, RF03, RF04, RF09, RF12, RF13 |
| RB09 | Confirmada | Arequipa; catálogo manual de 20–30 lugares reales por `seed.sql`. Zonas: Centro Histórico, Yanahuara, Cayma, Vallecito, Cercado. Categorías: Restaurantes, Cafés y Postres, Bares, Entretenimiento y Cultura. | — | RF03, RF04, RF11 |
| RB10 | Parcial | Dato revisado = verificado por el equipo, con `fuente` y `fecha_revision` en el registro; lo no verificado se deja vacío y se muestra como desconocido. | Cuándo se considera antiguo un dato (fuera del alcance de las 4 semanas). | RF04, RF11 |
| RB11 | Confirmada | El reemplazo de una actividad lo decide y aplica directamente un administrador, sin nueva votación; conserva posición y fecha/hora. | — | RF08, RF10 |
| RB12 | Confirmada | Código de 6 caracteres alfanuméricos en mayúsculas (ej. `AQP48X`), visible tras crear el plan; no caduca; inactivo solo si el plan está `cancelado`; se puede unir en cualquier fase activa (en `confirmado` va directo a itinerario y asistencia). | — | RF02, RF09 |
| RB13 | Parcial | Actividades 1–5 (por defecto 3); administradores ordenan, asignan fecha/hora y confirman. Zona horaria `America/Lima`. | Conflictos temporales y duración (no se validan en el MVP). | RF01, RF09, RF12, RF18 |
| RB14 | Confirmada | Candidatos 2–10 (por defecto 6) y actividades 1–5 (por defecto 3), configurables hasta abrir la votación; límites y candidatos fijos desde entonces; sin reapertura. | — | RF05, RF06, RF08, RF12, RF18 |
| RB15 | Confirmada | Recomendaciones con zona, categoría y presupuesto obligatorios: precio estimado ≤ presupuesto, orden por precio ascendente, máximo 10; precio desconocido excluido. | — | RF03, RF12, RF13 |
| RB16 | Confirmada | Avisos automáticos (tabla `notificaciones` + avisos locales con `flutter_local_notifications`, sin push remoto): 30 min antes de actividades y ante cambios/cancelación. Plazo de voto y plazo de asistencia independientes, fijados por administradores; un único aviso 1 h antes de cada plazo solo a pendientes. Guardar elecciones completa el voto; asistiré o no asistiré completa la asistencia. | — | RF07, RF09, RF14, RF16, RF17 |
| RB17 | Confirmada | Avisos de actividad, cambio y cancelación a participantes con asistencia `pendiente` o `asistire` (se excluye `no_asistire`). Al cambiar horario o cancelar se anulan los avisos anteriores y se generan los nuevos; el dispositivo los aplica al sincronizar. Si el momento del recordatorio ya pasó, no se programa. | — | RF10, RF12, RF14 |
| RB18 | Confirmada | Asistencia para toda la salida, visible para el plan: `pendiente` solo inicial; se elige y cambia entre asistiré y no asistiré, sin volver a pendiente. Plazo opcional y no bloqueante («Plazo vencido» sin impedir cambios). Los cambios del plan no reinician respuestas. | — | RF14, RF16 |
| RB19 | Confirmada | El creador es el primer administrador, no puede abandonar el plan ni perder el rol (solo cancelar). Los administradores nombrados lo son de forma permanente; no hay retiro de administradores en el MVP. | — | RF01, RF17 |

---

## 8. Requisitos no funcionales (RNF01–RNF08)

| ID | Requisito | Verificación / pendiente |
|---|---|---|
| RNF01 | El flujo principal será usable en **Android e iOS** desde una única base de código Flutter, con controles legibles y mensajes claros. El código y los paquetes de `pubspec.yaml` deben ser 100 % compatibles con ambas plataformas; no se usan paquetes, permisos o diseños exclusivos de una de ellas. | No hay Mac disponible: todas las pruebas y compilaciones del desarrollo se hacen en Android. La compilación iOS no se verificará durante el MVP. |
| RNF02 | Un guardado fallido no se presenta como exitoso; los reintentos no duplican planes, propuestas, participaciones ni votos. | Probar fallos de conexión, reenvío y acciones simultáneas. |
| RNF03 | Los permisos se aplican en el servidor (RLS + funciones SQL), además de en la interfaz. | Comprobar accesos con y sin permiso, con varias cuentas y varios planes. |
| RNF04 | Se solicitan únicamente los datos personales necesarios para participar. | Definir datos recogidos, visibilidad, conservación y eliminación. |
| RNF05 | La interfaz distingue carga, ausencia de datos, información incompleta y error. | Revisar estos estados en cada pantalla. |
| RNF06 | El rendimiento soporta los grupos y el catálogo definidos para la prueba. | Acordar volumen, concurrencia y tiempo de respuesta objetivo. |
| RNF07 | La fuente y revisión de los datos de lugares son trazables. | Procedimiento y frecuencia; auditar una muestra del catálogo. |
| RNF08 | La solución queda **feature complete el 2026-11-12** (3 semanas), con una semana de estabilización hasta el 2026-11-19 sin funciones nuevas, con una dedicación máxima de **7 horas semanales por integrante** (≈ 14 h/semana, ~46 h hasta el 11-12 + ~14 h de colchón), y a costo cero en servicios (plan gratuito de Supabase, sin Apple Developer, sin SMTP, sin FCM). | Priorizar el recorrido completo frente al detalle visual. Considerar la pausa del proyecto gratuito de Supabase tras una semana de inactividad. |

---

## 9. Pantallas (P01–P12)

Las vistas pueden combinarse si conservan acciones y estados. Estados globales a representar donde apliquen: carga, lista vacía, validación, error de guardado, sesión no iniciada, error de acceso/registro, código inválido, voto guardado, votación cerrada, empate, ausencia de votos, dato desconocido, cambio no confirmado, itinerario vacío, actividad sin fecha/hora, sin recomendaciones compatibles, permiso de notificaciones denegado, asistencia pendiente/asistiré/no asistiré.

### P01 Crear salida — pestaña Mis salidas
- **Rol.** Cualquier usuario con sesión; queda como primer administrador. RF01, RF17, RF18.
- **Contenido/acciones.** Pantalla dedicada (no incrustada en Mis salidas). Campos: nombre del plan y presupuesto en soles por persona (solo actividades), más los límites precargados y editables con su rango: propuestas por persona (3, 1–5), candidatos (6, 2–10), selecciones (3, 1–5, ≤ candidatos), actividades (3, 1–5). Botón _Crear plan_. Al crear → detalle del plan con código y _Copiar código_.
- **Estados.** Edición, campo inválido, guardando, error con datos conservados, plan creado.
- **Pendiente.** —

### P02 Unirse con código — pestaña Mis salidas
- **Rol.** Usuario con sesión. RF02, RF15.
- **Contenido/acciones.** Campo de código de 6 caracteres (se convierte a mayúsculas) y _Unirse_; identifica el plan sin duplicar participación. Tras unirse, navega al detalle según la fase (en `confirmado`, itinerario y asistencia).
- **Estados.** Sesión no iniciada, validación (6 caracteres), consultando, código inválido o de plan cancelado, error de conexión, cuenta ya participante.
- **Pendiente.** —

### P03 Consultar lugares — pestaña Explorar lugares
- **Rol.** Usuario con sesión. RF03.
- **Contenido/acciones.** Lista/tarjetas de los 20–30 lugares de Arequipa (precio orientativo, zona, categoría) y acceso a ficha. Búsqueda/filtros adicionales solo si se aprueban.
- **Estados.** Carga, con opciones, vacía, error.
- **Pendiente.** Filtros de exploración adicionales.

### P04 Ficha del lugar — pestaña Explorar lugares
- **Rol.** Usuario con sesión; propone si participa en algún plan en `recibiendo_propuestas`. RF04, RF05.
- **Contenido/acciones.** Ubicación, horario de atención, precio orientativo, información faltante; _Proponer al grupo_ con **selector de plan destino**.
- **Estados.** Carga, dato incompleto, error, propuesta guardada/fallida, límite de propuestas alcanzado.
- **Pendiente.** Unidad del precio, abrir mapas. Solo se proponen lugares del catálogo; el selector lista planes en `recibiendo_propuestas`.

### P05 Decisión del grupo (Preparar votación / Votar / Gestionar votación) — Mis salidas › detalle
- **Rol.** Participantes y administradores. RF05–RF08, RF14, RF17, RF18.
- **Contenido/acciones.**
  - _Recibiendo propuestas_: participante ve propuestas y puede _Proponer lugares_ (va a Explorar con destino elegido); administrador además accede a **Preparar votación**: elegir candidatos (≤ máximo), configurar límites 6/3/3, fijar plazo de voto, _Abrir votación_.
  - _En votación_: participante **Votar** (selección múltiple con contador del máximo, _Guardar votos_, totales por lugar sin nombres, plazo visible); administrador además **Gestionar votación** (_Cerrar votación_ manual).
  - _Cerrada_: resultado ordenado por votos; administrador resuelve empates.
- **Estados.** Preparación, votación abierta, selección en edición, voto guardado, error de guardado, cierre rechazado (0 candidatos o 0 votos), votación cerrada, resultado, empate en el último puesto. Lista/límites mostrados como fijos durante la votación.
- **Pendiente.** — (totales por recarga al abrir y al deslizar; sin reapertura).

### P06 Plan acordado (detalle de salida, asistencia y grupo) — Mis salidas › detalle
- **Rol.** Participantes; acciones de cambio/cancelación solo administradores. RF09, RF10, RF12, RF16, RF17.
- **Contenido/acciones.** Fase del plan, código, actividades ordenadas con fecha/hora, datos de lugares, presupuesto y gasto estimado por persona, advertencia de exceso, asistencia (_Asistiré_ / _No asistiré_, sin opción de volver a pendiente) con plazo opcional e indicador «Plazo vencido», estados del grupo; _Cambiar actividad_ y _Cancelar plan_ para administradores.
- **Estados.** Carga, resumen vigente, estimación incompleta, exceso, asistencia pendiente/asistiré/no asistiré, error de guardado, cambio en curso, cancelado.
- **Pendiente.** Punto de reunión (formato del resumen compartido confirmado 2026-11-09, ver RF09).

### P07 Elegir reemplazo — Mis salidas › detalle
- **Rol.** Administrador. RF10.
- **Contenido/acciones.** Actividad actual, estimación actual y proyectada, y alternativas: candidatos de la votación no elegidos y catálogo con chips de zona y categoría (sin lugares del itinerario); el administrador elige y _Confirmar reemplazo_ aplica el cambio directamente, sin votación. Se conservan posición y fecha/hora.
- **Estados.** Cargando alternativas, sin alternativas, alternativa elegida sin confirmar, error, cambio guardado.
- **Pendiente.** —

### P08 Revisar itinerario — Mis salidas › detalle
- **Rol.** Administradores editan; participantes consultan. RF08, RF12, RF18.
- **Contenido/acciones.** Lugares más votados hasta el máximo; orden manual, fecha/hora por actividad, estimación total por persona, advertencia de exceso que permite confirmar, _Confirmar itinerario_.
- **Estados.** Vacío, actividad sin fecha/hora, edición, guardando, error, costo incompleto, exceso, confirmado.
- **Pendiente.** Duración, traslados, conflictos (no se validan en el MVP). Fechas en `America/Lima`.

### P09 Consultar recomendaciones — pestaña Explorar lugares
- **Rol.** Usuario con sesión. RF13.
- **Contenido/acciones.** Entradas obligatorias zona, categoría y presupuesto; hasta 10 lugares sugeridos de más económico a más caro, acceso a ficha, _Proponer_ (con plan destino) o «Ya propuesto».
- **Estados.** Consultando, con recomendaciones, sin opciones compatibles, error.
- **Pendiente.** —

### P10 Notificaciones — pestaña Notificaciones
- **Rol.** Usuario con sesión. RF14.
- **Contenido/acciones.** Historial (tabla `notificaciones`) con nombre del plan, tipo y hora; abrir → contexto (voto → P05; asistencia → P06; actividad/cambio/cancelación → P06). Estado del permiso de notificaciones del dispositivo y acción para concederlo. Explicación breve de qué eventos generan avisos y de que los cambios de otros se reciben al abrir la app.
- **Estados.** Permiso no concedido/denegado, habilitados, historial vacío, error.
- **Pendiente.** Preferencias (no se implementan; no inventar interruptores).

### P11 Registrarse e iniciar sesión — fuera de pestañas; cierre de sesión en Perfil
- **Rol.** Cualquier persona. RF15.
- **Contenido/acciones.** Registro (nombre visible, correo, contraseña) e inicio de sesión (correo, contraseña); acceso inmediato sin confirmación por correo; cierre de sesión desde Perfil. Puede dividirse en varias vistas. **Sin acceso con Google y sin «¿Olvidaste tu contraseña?»** en la implementación.
- **Estados.** Validación, enviando, error (credenciales incorrectas, correo ya registrado, sin conexión), acceso correcto.
- **Pendiente.** —

### P12 Participantes y administradores — integrable en P06
- **Rol.** Participantes consultan; administradores nombran. RF16, RF17.
- **Contenido/acciones.** Lista de participantes (nombre visible) con rol y asistencia; _Nombrar administrador_ solo para administradores. El rol es permanente; el creador se identifica y no puede perderlo. Nunca mostrar nombres asociados a los votos.
- **Estados.** Carga, datos, asignando, asignación guardada, error con roles conservados.
- **Pendiente.** —

**Perfil (pestaña).** Perfil básico de la cuenta: nombre visible (editable, confirmado 2026-10-22), correo y _Cerrar sesión_. Sin foto, ubicación, idioma, preferencias de avisos, cambio de contraseña ni cuentas vinculadas. Sin funciones sociales.

---

## 10. Flujos principales

- **A · Organizar (administrador).** P11 acceso → P01 crear (rol de primer administrador) → detalle con código → compartir código → P03/P09 → P04 proponer → P05 _Preparar votación_ (candidatos, límites, plazo de voto) → _Abrir votación_ → P05 _Cerrar votación_ → resolver empates → P08 ordenar y asignar fecha/hora, revisar presupuesto → confirmar → P06 (fija plazo de asistencia).
- **B · Participar.** P11 acceso → P02 código → detalle del plan → P03/P09 → P04 proponer (eligiendo plan) → P05 votar, guardar y modificar hasta el cierre → P06 ver itinerario → responder asistencia → recibir avisos.
- **C · Reemplazo (administrador).** P06 → P07 alternativas de la votación o del catálogo → _Confirmar reemplazo_ (directo, sin votación) → P06 actualizado + aviso de cambio a participantes con asistencia pendiente o asistiré.
- **D · Cancelación (administrador).** P06 → _Cancelar plan_ → guardado → P06 con estado cancelado + aviso automático + anulación de avisos de actividades.
- **E · Avisos.** Conceder permiso → la app sincroniza `notificaciones` y programa avisos locales → el aviso se dispara (también con la app cerrada) → abrir contexto (P05/P06). Los cambios de otros se reciben al abrir la app. Representar permiso denegado.
- **F · Administración.** P06/P12 → ver participantes y roles → _Nombrar administrador_ → guardar → roles vigentes.

## 11. Modelo conceptual de datos

| Concepto | Información | Pendiente |
|---|---|---|
| Plan | Identificador, nombre, estado (fase), presupuesto, itinerario confirmado. | Campos, fechas y ciclo de vida definitivos. |
| Código de invitación | Código asociado a un plan para unirse desde la app con cuenta. | Formato, caducidad, revocación, fases. |
| Configuración del plan | Máximos de propuestas por persona, candidatos, selecciones y actividades (3/6/3/3); fijos mientras se vota; presupuesto PEN por persona; plazos independientes de voto y asistencia. | Rangos, reapertura, zona horaria, modificación de plazos. |
| Cuenta / perfil | Identificador estable, correo y `nombre_visible` (obligatorio); credenciales gestionadas por Supabase Auth sin confirmación de correo. | — |
| Participación | Cuenta vinculada al plan y rol (administrador/participante). | Retiro de roles. No hay participación sin cuenta. |
| Lugar | Identificador, nombre, categoría, zona, ubicación, horario de atención, precio estimado PEN, procedencia y fecha de revisión. | Fuente, cobertura, unidad del precio, datos obligatorios. |
| Propuesta | Plan, lugar (único por plan, solo del catálogo), quien propone; retirable en `recibiendo_propuestas` por su autor o un admin. | — |
| Candidato | Lugar incluido en la lista final por administradores (≤ máximo). | — |
| Voto | Participante y selección vigente sobre candidatos; última selección guardada; ≤ máximo. Solo visible a su titular; los demás ven totales. | — |
| Actividad de itinerario | Plan, lugar, posición, fecha y hora asignadas por administradores. | Duración, validación temporal. |
| Cambio de plan | Plan, actividad, opción anterior y nueva, quién y cuándo. | Historial y comunicación. |
| Notificación / recordatorio | Destinatario, plan/actividad, tipo, momento previsto, estado (activa/anulada), entrega y lectura; fuente para avisos locales del dispositivo. | — |
| Notificación | Historial por usuario con nombre del plan y destino. | — |
| Respuesta de asistencia | Participación y estado vigente (pendiente solo inicial; asistiré / no asistiré), visible al plan; plazo no bloqueante. | — |
| Preferencias de recomendación | Zona, categoría y presupuesto, obligatorios y usados solo durante la consulta. | — |

Esquema físico: `04_DATABASE_SCHEMA.md`.

## 12. Validación del MVP (para la semana 4)

| Aspecto | Medición |
|---|---|
| Completar la decisión | Tiempo desde que el grupo recibe opciones hasta que confirma el plan (referencia actual: cerca de 1 hora). |
| Participar sin ayuda | Personas que acceden, entienden opciones y registran su voto. |
| Comprender la información | Identificar ubicación, horario y precio antes de elegir. |
| Cambiar de plan | Tiempo y éxito al confirmar una alternativa. |
| Entender el itinerario | Identificar qué actividad sigue y su fecha/hora. |
| Usar una recomendación | Encontrar una sugerencia compatible y llevarla a la decisión. |
| Recibir un recordatorio | Actividad a 30 min, cambios/cancelación y un aviso por acción pendiente 1 h antes; exclusión correcta. |
| Registrarse, unirse y responder asistencia | Acceso, unión con código y asistencia visible al grupo correcto. |

## 13. Criterios de entrega del MVP

1. Varias cuentas crean/se unen a un plan persistente y distinguen roles.
2. Se consultan lugares y se proponen al plan correcto respetando los límites.
3. Se prepara/vota/cierra con selecciones editables, totales coherentes y privacidad de votos.
4. Se confirma un itinerario ordenado con horarios, presupuesto y advertencias.
5. Se consulta/modifica asistencia visible al grupo.
6. Se modifica o cancela una salida y se actualizan sus avisos.
7. Funcionan avisos locales automáticos de actividades y recordatorios solo a pendientes (también con la app cerrada), avisos de cambio/cancelación al sincronizar, con historial y nombre del plan.
8. Se instala y demuestra en Android (APK); el código y `pubspec.yaml` se mantienen compatibles con iOS (compilación iOS no verificada por falta de Mac). Ambos usuarios ejecutan el proyecto con las instrucciones.

Si el tiempo no alcanza, simplificar primero presentación (animaciones, detalles visuales, volumen del catálogo). **No retirar silenciosamente** itinerarios, recomendaciones, asistencia o notificaciones: consultar a los usuarios.
