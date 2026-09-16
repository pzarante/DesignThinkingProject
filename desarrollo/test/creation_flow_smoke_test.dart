import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:f_clean_template/app_routes.dart';
import 'package:f_clean_template/core/app_theme.dart';
import 'package:f_clean_template/features/community_creation/community_creation_dependencies.dart';
import 'package:f_clean_template/features/home/home_dependencies.dart';
import 'package:f_clean_template/features/project_creation/project_creation_dependencies.dart';
import 'package:f_clean_template/features/project_detail/project_detail_dependencies.dart';

Widget _app(String initialRoute) => GetMaterialApp(
  theme: AppTheme.light,
  initialRoute: initialRoute,
  getPages: AppRoutes.pages,
);

void main() {
  setUp(() {
    Get.testMode = true;
    registerHome();
    registerProjectDetail();
    registerProjectCreation();
    registerCommunityCreation();
  });

  tearDown(Get.reset);

  testWidgets('project wizard walks 6 steps, reviews and publishes', (
    tester,
  ) async {
    await tester.pumpWidget(_app(AppRoutes.createProject));
    await tester.pumpAndSettle();

    expect(find.text('Etapa del proyecto'), findsOneWidget);
    await tester.tap(find.text('Formación de equipo'));
    await tester.pump();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    expect(find.text('Información básica'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'EcoCampus');
    await tester.enterText(
      find.byType(TextField).at(1),
      'Gestión de residuos del campus.',
    );
    await tester.pump();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Hay muchos residuos.');
    await tester.pump();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Compostar.');
    await tester.pump();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    expect(find.text('Equipo'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    expect(find.text('Recursos'), findsOneWidget);
    await tester.tap(find.text('Revisar proyecto'));
    await tester.pumpAndSettle();

    expect(find.text('Revisar proyecto'), findsWidgets);
    expect(find.text('EcoCampus'), findsOneWidget);

    await tester.tap(find.text('Publicar proyecto'));
    await tester.pumpAndSettle();

    expect(find.text('¡Proyecto creado!'), findsOneWidget);

    // Lo escrito en el asistente llega a la ficha del proyecto publicado.
    await tester.tap(find.text('Ver proyecto'));
    await tester.pumpAndSettle();

    expect(find.text('EcoCampus'), findsOneWidget);
    expect(find.text('Creado por María García'), findsOneWidget);
    expect(find.text('Crear publicación'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Hay muchos residuos.'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('El Problema'), findsOneWidget);
  });

  testWidgets('community form links a project and creates the community', (
    tester,
  ) async {
    await tester.pumpWidget(_app(AppRoutes.createCommunity));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Club de Innovación');
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Seleccionar proyecto existente'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seleccionar proyecto existente'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('MotionLab'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar selección'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(FilledButton, 'Crear comunidad'),
    );
    await tester.pumpAndSettle();

    expect(find.text('¡Comunidad creada!'), findsOneWidget);
  });
}
