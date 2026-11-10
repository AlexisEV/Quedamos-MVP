# Quedamos

App móvil para organizar salidas grupales. Un grupo crea un plan, se une con un código de 6
caracteres, propone lugares del catálogo, vota, y los administradores cierran la votación, ordenan el
itinerario con fecha y hora y lo confirman. Cada participante responde su asistencia y recibe avisos locales
(30 min antes de cada actividad, 1 h antes de los plazos de voto y asistencia, y cuando el plan cambia o se cancela).

Pestañas: **Mis salidas**, **Explorar lugares**, **Avisos** y **Perfil**.

## Tecnologías

| Capa | Tecnología |
|---|---|
| App | Flutter (Dart), Material 3, `go_router`, `provider` + `ChangeNotifier` |
| Backend | Supabase: Auth (correo y contraseña), PostgreSQL con RLS y funciones RPC |
| Avisos | Tabla `notificaciones` sincronizada por triggers + `flutter_local_notifications`|

El código es compatible con Android e iOS; las compilaciones y pruebas del MVP se hacen en Android.

## Requisitos

- Flutter 3.47 o superior (Dart 3.13) y Android SDK con un emulador o un teléfono Android (API 24+).
- Node.js para usar la CLI de Supabase con `npx supabase` (no hace falta Docker).
- Un proyecto de Supabase (plan gratuito) con **Authentication › Email › «Confirm email» desactivado**.

## Configuración

1. Instalar dependencias:

   ```bash
   flutter pub get
   ```

2. Crear `.env.json` en la raíz copiando `env.example.json` y completar los dos valores del proyecto de
   Supabase (Project Settings › API): la URL del proyecto y la clave pública (*publishable* / *anon*).
   `.env.json` está en `.gitignore`: **nunca** se versiona ni se usa la clave `service_role`.

3. Preparar la base de datos (desde la raíz del proyecto):

   ```bash
   npx supabase login
   npx supabase link --project-ref <ref-del-proyecto>
   npx supabase db push --linked
   npx supabase db query --linked --yes -f supabase/seed.sql
   ```

   `db push` aplica en orden las migraciones de `supabase/migrations/` (tablas, RLS, RPC y avisos).
   `seed.sql` carga el catálogo de 28 lugares de `supabase/catalogo_lugares.csv` y se puede volver a ejecutar.
   Para comprobar el estado: `npx supabase migration list --linked`.

## Ejecutar

```bash
flutter run --dart-define-from-file=.env.json
```

## Pruebas

```bash
flutter analyze
flutter test
```

## APK para instalar en un teléfono

```bash
flutter build apk --release --dart-define-from-file=.env.json
```

La APK queda en `build/app/outputs/flutter-apk/app-release.apk`. Se copia al teléfono y se instala
permitiendo «instalar apps desconocidas». Está firmada con la clave de depuración de la máquina que la
compila: sirve para instalarla directamente, no para publicarla en Play Store. Si el teléfono ya tiene una
versión compilada en otra máquina, hay que desinstalarla antes. Al abrir la app por primera vez se pide el
permiso de notificaciones.

## Estructura

```
lib/
  app/         tema, rutas y arranque
  core/        errores, utilidades y widgets compartidos
  features/    auth, salidas, lugares, votacion, itinerario, notificaciones, perfil
               (cada una con data/ y presentation/: Screen → ViewModel → Repository)
supabase/
  migrations/  esquema, RLS, RPC y triggers de avisos
  seed.sql     catálogo de lugares
test/          pruebas de modelos, view models y pantallas
```

Las pantallas no hablan con Supabase directamente; toda escritura con reglas de negocio pasa por una RPC.
