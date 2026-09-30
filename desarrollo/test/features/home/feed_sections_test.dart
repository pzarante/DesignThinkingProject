import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:f_clean_template/core/app_theme.dart';
import 'package:f_clean_template/core/widgets/app_section_header.dart';
import 'package:f_clean_template/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:f_clean_template/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:f_clean_template/features/home/domain/models/community.dart';
import 'package:f_clean_template/features/home/domain/models/home_feed.dart';
import 'package:f_clean_template/features/home/domain/models/opportunity.dart';
import 'package:f_clean_template/features/home/domain/models/project.dart';
import 'package:f_clean_template/features/home/domain/repositories/i_home_repository.dart';
import 'package:f_clean_template/features/home/ui/viewmodels/home_controller.dart';
import 'package:f_clean_template/features/home/ui/views/home_page.dart';
import 'package:f_clean_template/features/notifications/notifications_dependencies.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_network_images.dart';

/// Feed controlado: lo que cambia entre pruebas es si hay oportunidades.
class _FakeHomeRepository implements IHomeRepository {
  _FakeHomeRepository({
    this.opportunities = const [],
    this.communities = const [Community(id: 'c1', name: 'Studio Creativo')],
    this.myProjects = const [
      Project(id: 'p1', name: 'MotionLab', isPinned: true),
    ],
  });

  final List<Opportunity> opportunities;
  final List<Community> communities;
  final List<Project> myProjects;

  @override
  Future<HomeFeed> getFeed() async => HomeFeed(
    followedCommunities: communities,
    recommendedProjects: const [Project(id: 'r1', name: 'Lector de Códigos')],
    opportunities: opportunities,
    myProjects: myProjects,
  );

  @override
  Future<Project> addProject(
    Project project, {
    required String problem,
    required String objective,
    String? scope,
    required int maxMembers,
    required String availability,
    String? coLeaderId,
    List<String> links = const [],
  }) async => project;

  @override
  Future<void> addCommunity(Community community) async {}

  @override
  Future<void> updateProject(Project project) async {}

  @override
  Future<void> updateCommunity(Community community) async {}
}

/// Busca un título de sección, no cualquier texto: "Mis Proyectos" también
/// es una pestaña de la barra inferior.
Finder _sectionHeader(String title) =>
    find.widgetWithText(AppSectionHeader, title);

Future<void> _pumpHome(
  WidgetTester tester, {
  required bool isAnonymous,
  List<Opportunity> opportunities = const [],
  bool withPersonalContent = true,
}) async {
  // Pantalla alta a propósito: el feed es una `ListView`, y lo que queda
  // fuera no llega a construirse, así que sin esto no se podría afirmar que
  // una sección no está (solo que no se ve).
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  useFakeNetworkImages();
  Get.testMode = true;
  registerFakeAuth(isAnonymous: isAnonymous);
  Get.put<IHomeRepository>(
    _FakeHomeRepository(
      opportunities: opportunities,
      communities: withPersonalContent
          ? const [Community(id: 'c1', name: 'Studio Creativo')]
          : const [],
      myProjects: withPersonalContent
          ? const [Project(id: 'p1', name: 'MotionLab', isPinned: true)]
          : const [],
    ),
  );
  Get.put(HomeController(Get.find()));
  Get.put(AuthenticationController(Get.find<IAuthRepository>()));
  registerNotifications();

  await tester.pumpWidget(
    GetMaterialApp(theme: AppTheme.light, home: const HomePage()),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  tearDown(Get.reset);

  testWidgets('con cuenta se ven las secciones personales', (tester) async {
    await _pumpHome(tester, isAnonymous: false);

    expect(_sectionHeader('Recomendado para ti'), findsOneWidget);
    expect(_sectionHeader('Comunidades que sigues'), findsOneWidget);
    expect(_sectionHeader('Mis Proyectos'), findsOneWidget);
  });

  testWidgets('como invitado no aparecen sus títulos', (tester) async {
    await _pumpHome(tester, isAnonymous: true);

    expect(_sectionHeader('Recomendado para ti'), findsOneWidget);
    expect(_sectionHeader('Comunidades que sigues'), findsNothing);
    expect(_sectionHeader('Mis Proyectos'), findsNothing);
  });

  testWidgets('sin oportunidades se avisa en vez de dejar el hueco', (
    tester,
  ) async {
    await _pumpHome(tester, isAnonymous: true);

    expect(_sectionHeader('Ferias y oportunidades'), findsOneWidget);
    expect(find.text('No hay eventos por el momento.'), findsOneWidget);
  });

  testWidgets('con cuenta pero sin nada propio, cada sección lo dice', (
    tester,
  ) async {
    await _pumpHome(tester, isAnonymous: false, withPersonalContent: false);

    expect(_sectionHeader('Comunidades que sigues'), findsOneWidget);
    expect(find.text('Todavía no sigues ninguna comunidad.'), findsOneWidget);
    expect(_sectionHeader('Mis Proyectos'), findsOneWidget);
    expect(
      find.text('Todavía no has creado ningún proyecto.'),
      findsOneWidget,
    );
  });

  testWidgets('con oportunidades se listan', (tester) async {
    await _pumpHome(
      tester,
      isAnonymous: true,
      opportunities: const [
        Opportunity(id: 'o1', name: 'Feria de Innovación', participatingProjects: 15),
      ],
    );

    expect(find.text('Feria de Innovación'), findsOneWidget);
    expect(find.text('No hay eventos por el momento.'), findsNothing);
  });
}
