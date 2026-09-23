import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:f_clean_template/app_routes.dart';
import 'package:f_clean_template/core/app_theme.dart';
import 'package:f_clean_template/features/home/data/datasources/local/local_home_source.dart';
import 'package:f_clean_template/features/home/domain/models/project.dart';
import 'package:f_clean_template/features/home/home_dependencies.dart';
import 'package:f_clean_template/features/project_applications/ui/viewmodels/applicants_controller.dart';
import 'package:f_clean_template/features/project_detail/project_detail_dependencies.dart';

import 'support/fake_auth_repository.dart';
import 'support/fake_network_images.dart';

Future<Project> _projectById(String id) async {
  final feed = await LocalHomeSource().getFeed();
  return [
    ...feed.myProjects,
    ...feed.recommendedProjects,
  ].firstWhere((project) => project.id == id);
}

/// Abre el detalle como lo hace la app: navegando con el proyecto del feed
/// como argumento.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _openDetail(WidgetTester tester, Project project) async {
  await tester.pumpWidget(
    GetMaterialApp(
      theme: AppTheme.light,
      getPages: AppRoutes.pages,
      home: const Scaffold(),
    ),
  );
  Get.toNamed(AppRoutes.projectDetail, arguments: project);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    useFakeNetworkImages();
    Get.testMode = true;
    registerFakeAuth();
    registerHome(remote: false);
    registerProjectDetail(remote: false);
  });

  tearDown(Get.reset);

  testWidgets('owner sees the full detail and can open its settings', (
    tester,
  ) async {
    await _openDetail(tester, await _projectById('p1'));

    expect(find.text('MotionLab'), findsOneWidget);
    expect(find.text('Creado por Ana Martínez'), findsOneWidget);
    expect(find.text('Crear publicación'), findsOneWidget);
    expect(find.text('Postularme'), findsNothing);

    await _scrollTo(tester, find.text('El Problema'));
    await _scrollTo(tester, find.text('Cronograma'));
    await _scrollTo(tester, find.text('Etiquetas'));

    await _scrollTo(tester, find.text('Equipo'));
    await tester.tap(find.text('Equipo'));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Integrantes (2/6)'));
    await _scrollTo(tester, find.text('Roles buscados'));

    await tester.tap(find.byTooltip('Configurar proyecto').first);
    await tester.pumpAndSettle();
    expect(find.text('Configurar proyecto'), findsWidgets);
    expect(find.text('Guardar cambios'), findsOneWidget);
  });

  testWidgets('a visitor sees the same information with other actions', (
    tester,
  ) async {
    await _openDetail(tester, await _projectById('r1'));

    expect(find.text('Lector de Códigos'), findsOneWidget);
    expect(find.text('Postularme'), findsOneWidget);
    await _scrollTo(tester, find.text('Descripción'));
    expect(find.text('Crear publicación'), findsNothing);
    expect(find.byTooltip('Configurar proyecto'), findsNothing);
  });

  testWidgets('a visitor can apply through the existing application flow', (
    tester,
  ) async {
    await _openDetail(tester, await _projectById('r1'));

    await tester.tap(find.text('Postularme'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Motivación'),
      'Quiero aportar en la parte de visión por computador.',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Disponibilidad'),
      '6 horas por semana',
    );
    await tester.tap(find.text('Enviar postulación'));
    await tester.pumpAndSettle();

    final ApplicantsController applicants = Get.find();
    await applicants.load('r1');
    expect(applicants.applications, hasLength(1));
    expect(applicants.applications.first.applicantName, 'María García');
    expect(applicants.applications.first.projectId, 'r1');
  });

  testWidgets('the posts tab stays empty on purpose', (tester) async {
    await _openDetail(tester, await _projectById('p1'));

    await _scrollTo(tester, find.text('Publicaciones'));
    await tester.tap(find.text('Publicaciones'));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Aún no hay publicaciones'));
  });
}
