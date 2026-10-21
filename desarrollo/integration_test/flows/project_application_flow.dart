import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f_clean_template/core/app_keys.dart';

import '../support/test_app.dart';

/// Texto del botón principal del detalle, que cambia según quién mira.
Finder _primaryAction(String label) => find.descendant(
  of: find.byKey(AppKeys.projectDetailPrimaryButton),
  matching: find.text(label),
);

/// Abre un proyecto del inicio tocando su tarjeta.
Future<void> _openProject(WidgetTester tester, String projectId) async {
  await scrollTo(tester, find.byKey(AppKeys.projectCard(projectId)));
  await tapAndSettle(tester, find.byKey(AppKeys.projectCard(projectId)));
  expect(find.byKey(AppKeys.projectDetailPage), findsOneWidget);
}

/// Cambia a la pestaña Equipo del detalle.
///
/// Las pestañas van debajo de la portada y el detalle es una lista perezosa:
/// primero hay que bajar hasta ellas.
Future<void> _openTeamTab(WidgetTester tester) async {
  await scrollTo(tester, find.text('Equipo'));
  await tapAndSettle(tester, find.text('Equipo'));
  await scrollTo(tester, find.text('Roles buscados'));
}

void projectApplicationFlowTests() {
  testWidgets('postularse a un proyecto ajeno -> queda pendiente', (
    tester,
  ) async {
    await startApp(tester);
    await logIn(tester);

    // Lector de Códigos es de otra persona y busca un Desarrollador Móvil.
    await _openProject(tester, 'r1');
    expect(find.text('Lector de Códigos'), findsOneWidget);
    expect(find.byKey(AppKeys.projectLeaveButton), findsNothing);
    expect(_primaryAction('Postularme'), findsOneWidget);

    await tapAndSettle(tester, find.byKey(AppKeys.projectDetailPrimaryButton));
    expect(find.byKey(AppKeys.applicationSubmitButton), findsOneWidget);

    // Vacío no se envía: lo primero que pide es la motivación.
    await tapAndSettle(tester, find.byKey(AppKeys.applicationSubmitButton));
    expect(find.text('Cuéntale al equipo cómo puedes aportar'), findsOneWidget);

    await tapAndSettle(tester, find.byKey(AppKeys.applicationRoleField));
    await tapAndSettle(tester, find.text('Desarrollador Móvil').last);
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(SegmentedButton<String>),
        matching: find.text('Part-time'),
      ),
    );
    await typeInto(
      tester,
      AppKeys.applicationMotivationField,
      'Tengo experiencia con la cámara en Flutter.',
    );
    await tapAndSettle(tester, find.byKey(AppKeys.applicationSubmitButton));

    // El formulario se cierra y el botón ya no deja postularse otra vez.
    expect(find.byKey(AppKeys.applicationSubmitButton), findsNothing);
    expect(find.text('Postulación enviada.'), findsOneWidget);
    expect(_primaryAction('Postulación pendiente'), findsOneWidget);
  });

  testWidgets('el líder acepta una postulación -> la persona entra al equipo', (
    tester,
  ) async {
    await startApp(tester);
    await logIn(tester);

    // MotionLab está anclado en "Mis Proyectos" y tiene postulaciones.
    await _openProject(tester, 'p1');
    await _openTeamTab(tester);
    expect(find.text('Integrantes (3/6)'), findsOneWidget);
    expect(find.text('Daniela Salamanca'), findsNothing);

    await tapAndSettle(tester, find.byKey(AppKeys.projectApplicantsButton));
    expect(find.byKey(AppKeys.applicantsPage), findsOneWidget);
    expect(find.text('Daniela Salamanca'), findsOneWidget);

    await tapAndSettle(
      tester,
      find.byKey(AppKeys.applicantAcceptButton('application-1')),
    );
    expect(find.text('Aceptado'), findsOneWidget);
    expect(
      find.byKey(AppKeys.applicantAcceptButton('application-1')),
      findsNothing,
    );

    // De vuelta en el detalle, ya cuenta como integrante.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _openTeamTab(tester);
    expect(find.text('Integrantes (4/6)'), findsOneWidget);
    expect(find.text('Daniela Salamanca'), findsOneWidget);
  });

  testWidgets('salir de un proyecto que lideras -> eliges nuevo líder', (
    tester,
  ) async {
    await startApp(tester);
    await logIn(tester);

    // ComicVerse lo creó la cuenta sembrada; Diego Soto es el otro integrante.
    await _openProject(tester, 'p2');
    await tapAndSettle(tester, find.byKey(AppKeys.projectLeaveButton));

    // La etiqueta de la hoja se pinta en mayúsculas.
    expect(find.text('ELEGIR NUEVO LÍDER'), findsOneWidget);
    await tapAndSettle(tester, find.text('Diego Soto'));

    expect(find.text('¿Estás seguro?'), findsOneWidget);
    expect(find.textContaining('Diego Soto pasará a liderarlo.'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(AppKeys.projectLeaveConfirmButton));

    // Salir devuelve al inicio con la confirmación.
    expect(find.byKey(AppKeys.homePage), findsOneWidget);
    expect(find.text('Saliste del proyecto'), findsOneWidget);
    await dismissSnackbars(tester);

    // En el equipo ya solo queda Diego, ahora como líder.
    await _openProject(tester, 'p2');
    await _openTeamTab(tester);
    expect(find.text('Diego Soto'), findsOneWidget);
    expect(find.text('María García'), findsNothing);
  });
}
