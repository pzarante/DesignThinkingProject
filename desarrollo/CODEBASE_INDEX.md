# Índice del código

## Qué es

**Innovation Hub** (paquete `f_clean_template`, el nombre de la plantilla de
la que partió) es una app Flutter para publicar proyectos universitarios,
formar equipo postulándose a sus roles y agruparlos en comunidades. El backend
es ROBLE (Uninorte OpenLab), por medio del paquete `roble`.

La estructura es Clean Architecture / MVVM por feature. GetX hace la
inyección de dependencias, la navegación y el estado reactivo.

## Arranque

- [`lib/main.dart`](lib/main.dart): `main()` llama a `registerDependencies()`
  y lanza `MyApp`, que abre en `AppRoutes.home`.
- `registerDependencies({preferences, remote})` registra preferencias, cliente
  de ROBLE, caché y cada feature. Con `remote: false`, cada feature usa su
  fuente en memoria en lugar de ROBLE; así corren las pruebas de integración.
- [`lib/app_routes.dart`](lib/app_routes.dart): todas las rutas con nombre y
  el orden de la barra inferior.

## `lib/core/`

- `roble_config.dart`: URL y `contractId` de ROBLE (se pueden cambiar con
  `--dart-define`).
- `roble_cache.dart`: memoria corta compartida de las tablas de ROBLE.
- `roble_read.dart`: lecturas de ROBLE con errores entendibles (por ejemplo,
  una tabla que no está marcada como pública).
- `error_message.dart`: convierte una excepción en un mensaje para la UI.
- `i_local_preferences.dart` y sus implementaciones: cifrada en móvil
  (`local_preferences_secured.dart`), `shared_preferences` en web.
- `app_keys.dart`: keys de los widgets que usan las pruebas de integración.
- `app_theme.dart`, `theme/`: tema, colores semánticos, espaciados y
  tipografía.
- `widgets/`: piezas compartidas (`AppTextField`, `AppFormActions`,
  `AppBottomNavBar`, `AppSuccessView`, portadas, chips, avisos...).

## Features (`lib/features/`)

Cada una sigue `domain/` (modelos y contratos), `data/` (fuentes y
repositorios) y `ui/` (controladores, pantallas, widgets), y se registra con
su `<feature>_dependencies.dart`. Las que tienen backend traen una fuente de
ROBLE y otra local (`data/datasources/local/`) con datos sembrados.

| Feature | Qué hace |
|---|---|
| `auth` | Login con correo o nombre de usuario, registro en dos pasos, sesión de invitado. |
| `home` | Inicio (feed), Explorar (proyectos y personas) y Mis Proyectos. |
| `creation` | La bifurcación "¿Proyecto o Comunidad?" del botón Crear. |
| `project_creation` | Asistente de seis pasos, revisión y publicación. |
| `project_detail` | Detalle del proyecto: publicaciones, equipo, comentarios, configuración y salir del proyecto. |
| `project_applications` | Postularse a un rol y la lista de postulantes (aceptar o rechazar). |
| `community_creation` | Formulario de comunidad y vínculo con proyectos. |
| `community_detail` | Feed de una comunidad. |
| `community_settings` | Configuración de una comunidad. |
| `profile` | Perfil propio o ajeno y búsqueda de personas. |
| `notifications` | Notificaciones de la app (tabla `notifications` en ROBLE). |

## Pruebas

- `test/`: unitarias y de widgets, con `flutter test`. Las corre el CI.
- `integration_test/`: la app completa en un dispositivo, en modo local. El
  punto de entrada es `app_test.dart`, que corre los flujos de `flows/`.
  - Android/escritorio: `flutter test integration_test/app_test.dart`.
  - Web: `flutter drive` con `test_driver/integration_test.dart`.

## Plataformas

`android/`, `ios/` y `web/` tienen su proyecto. En `linux/` solo están los
archivos generados de plugins, sin el runner: `flutter run -d linux` no
funciona hasta agregarlo con `flutter create --platforms=linux .`.
