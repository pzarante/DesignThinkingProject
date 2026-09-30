import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:f_clean_template/app_routes.dart';
import 'package:f_clean_template/core/app_theme.dart';
import 'package:f_clean_template/features/community_detail/community_detail_dependencies.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_network_images.dart';

Future<void> _openCommunity(WidgetTester tester, String id) async {
  tester.view.physicalSize = const Size(400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    GetMaterialApp(
      theme: AppTheme.light,
      getPages: AppRoutes.pages,
      home: const Scaffold(),
    ),
  );
  Get.toNamed(AppRoutes.community, arguments: id);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    useFakeNetworkImages();
    Get.testMode = true;
    registerFakeAuth();
    registerCommunityDetail(remote: false);
  });

  tearDown(Get.reset);

  testWidgets('el feed enseña la comunidad y los proyectos que acoge', (
    tester,
  ) async {
    await _openCommunity(tester, 'c1');

    expect(find.text('Studio Creativo UNI'), findsOneWidget);
    expect(find.text('12 miembros'), findsOneWidget);
    expect(find.text('1 proyecto en la comunidad'), findsOneWidget);
    expect(find.text('MotionLab'), findsOneWidget);
  });

  testWidgets('seguir la comunidad cambia el botón', (tester) async {
    await _openCommunity(tester, 'c1');

    expect(find.text('Seguir comunidad'), findsOneWidget);
    await tester.tap(find.text('Seguir comunidad'));
    await tester.pumpAndSettle();

    expect(find.text('Siguiendo'), findsOneWidget);
    expect(find.text('Seguir comunidad'), findsNothing);
  });

  testWidgets('una comunidad que no existe lo dice', (tester) async {
    await _openCommunity(tester, 'no-existe');

    expect(find.text('No se pudo abrir la comunidad'), findsOneWidget);
  });
}
