import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:f_clean_template/app_routes.dart';
import 'package:f_clean_template/core/app_theme.dart';
import 'package:f_clean_template/features/home/home_dependencies.dart';
import 'package:f_clean_template/features/profile/profile_dependencies.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_network_images.dart';

Future<void> _open(WidgetTester tester, String route) async {
  await tester.pumpWidget(
    GetMaterialApp(
      theme: AppTheme.light,
      getPages: AppRoutes.pages,
      home: const Scaffold(),
    ),
  );
  Get.toNamed(route);
  await tester.pumpAndSettle();
}

/// Igual que [_open] pero sin esperar a que todo quede quieto.
///
/// La pestaña de proyectos pinta `ProjectCard`s cuyas portadas son
/// `Image.network`: en pruebas la carga nunca termina y su indicador de
/// progreso deja `pumpAndSettle` girando hasta agotar el tiempo.
Future<void> _openWithoutSettling(WidgetTester tester, String route) async {
  await tester.pumpWidget(
    GetMaterialApp(
      theme: AppTheme.light,
      getPages: AppRoutes.pages,
      home: const Scaffold(),
    ),
  );
  Get.toNamed(route);
  for (var frame = 0; frame < 5; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() {
    useFakeNetworkImages();
    Get.testMode = true;
    registerFakeAuth();
    registerProfile(remote: false);
    registerHome(remote: false);
  });

  tearDown(Get.reset);

  testWidgets('el perfil propio muestra identidad, contadores y proyectos', (
    tester,
  ) async {
    await _open(tester, AppRoutes.profile);

    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.text('María García'), findsOneWidget);
    expect(find.text('@mariagarcia'), findsOneWidget);
    expect(find.text('Ingeniería de Sistemas · 4º semestre'), findsOneWidget);

    // Los tres contadores del encabezado.
    expect(find.text('Proyectos'), findsOneWidget);
    expect(find.text('Equipos'), findsOneWidget);
    expect(find.text('Comunidades'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('MotionLab'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('MotionLab'), findsOneWidget);
  });

  testWidgets('buscar por user_name en Explorar abre ese perfil', (
    tester,
  ) async {
    await _openWithoutSettling(tester, AppRoutes.explore);

    await tester.tap(find.text('Personas'));
    await tester.pumpAndSettle();

    // Sin texto escrito la pestaña ya lista a todo el mundo.
    expect(find.text('@mariagarcia'), findsOneWidget);
    expect(find.text('@anamartinez'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'anamar');
    await tester.pumpAndSettle();
    expect(find.text('@anamartinez'), findsOneWidget);
    expect(find.text('@mariagarcia'), findsNothing);

    await tester.tap(find.text('@anamartinez'));
    await tester.pumpAndSettle();

    expect(find.text('Ana Martínez'), findsOneWidget);
    // Es el perfil de otra persona, no el propio.
    expect(find.text('Mi perfil'), findsNothing);
    // Y por eso su correo no se enseña.
    expect(find.text('ana@uni.edu'), findsNothing);
  });

  testWidgets('como invitado, el perfil invita a crear una cuenta', (
    tester,
  ) async {
    Get.reset();
    useFakeNetworkImages();
    Get.testMode = true;
    registerFakeAuth(isAnonymous: true);
    registerProfile(remote: false);

    await _open(tester, AppRoutes.profile);

    expect(find.text('Aun no te conocemos'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('Ya tengo cuenta'), findsOneWidget);
  });

  testWidgets('una cuenta sin fila en users avisa en vez de quedar en blanco', (
    tester,
  ) async {
    Get.reset();
    useFakeNetworkImages();
    Get.testMode = true;
    registerFakeAuth(id: 'sin-perfil');
    registerProfile(remote: false);

    await _open(tester, AppRoutes.profile);

    expect(find.text('No se pudo abrir el perfil'), findsOneWidget);
  });
}
