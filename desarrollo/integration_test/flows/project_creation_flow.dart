import 'package:flutter_test/flutter_test.dart';

import 'package:f_clean_template/core/app_keys.dart';

import '../support/test_app.dart';

void projectCreationFlowTests() {
  testWidgets('asistente de 6 pasos -> revisar -> publicar -> ver el proyecto', (
    tester,
  ) async {
    await startApp(tester);
    await logIn(tester);

    await tapAndSettle(tester, find.byKey(AppKeys.homeCreateButton));
    await tapAndSettle(tester, find.byKey(AppKeys.createOptionProject));
    await tapAndSettle(tester, find.byKey(AppKeys.createContinueButton));
    expect(find.byKey(AppKeys.projectWizardPage), findsOneWidget);

    // Paso 1: etapa. Sin elegir una, no se avanza.
    expect(isEnabled(tester, AppKeys.wizardNextButton), isFalse);
    await tapAndSettle(
      tester,
      find.byKey(AppKeys.stageOption('Formación de equipo')),
    );
    await tapAndSettle(tester, find.byKey(AppKeys.wizardNextButton));

    // Paso 2: nombre y descripción, los dos obligatorios.
    expect(isEnabled(tester, AppKeys.wizardNextButton), isFalse);
    await typeInto(tester, AppKeys.projectNameField, 'Huerto Solar');
    expect(isEnabled(tester, AppKeys.wizardNextButton), isFalse);
    await typeInto(
      tester,
      AppKeys.projectDescriptionField,
      'Huerto del campus regado con energía solar.',
    );
    await tapAndSettle(tester, find.byKey(AppKeys.wizardNextButton));

    // Paso 3: problema.
    await typeInto(
      tester,
      AppKeys.projectProblemField,
      'Las zonas verdes se riegan con agua potable.',
    );
    await tapAndSettle(tester, find.byKey(AppKeys.wizardNextButton));

    // Paso 4: objetivo.
    await typeInto(
      tester,
      AppKeys.projectObjectiveField,
      'Regar el huerto solo con agua lluvia y bombas solares.',
    );
    await tapAndSettle(tester, find.byKey(AppKeys.wizardNextButton));

    // Pasos 5 (equipo) y 6 (recursos) tienen valores por defecto.
    expect(find.text('Equipo'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(AppKeys.wizardNextButton));
    expect(find.text('Revisar proyecto'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(AppKeys.wizardNextButton));

    // Revisión: lo escrito en el asistente, antes de publicar.
    expect(find.byKey(AppKeys.projectReviewPage), findsOneWidget);
    expect(find.text('Huerto Solar'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(AppKeys.projectPublishButton));

    expect(find.byKey(AppKeys.projectCreatedPage), findsOneWidget);
    expect(find.text('¡Proyecto creado!'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(AppKeys.projectCreatedViewButton));

    // El detalle lo abre quien lo creó: puede publicar, no postularse.
    expect(find.byKey(AppKeys.projectDetailPage), findsOneWidget);
    expect(find.text('Huerto Solar'), findsOneWidget);
    expect(find.text('Creado por ${SeededAccount.userName}'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(AppKeys.projectDetailPrimaryButton),
        matching: find.text('Crear publicación'),
      ),
      findsOneWidget,
    );

    // Volver deja en el inicio, y el proyecto ya está en "Mis Proyectos".
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(AppKeys.homePage), findsOneWidget);

    await tapAndSettle(tester, find.byKey(AppKeys.navMyProjects));
    expect(find.byKey(AppKeys.myProjectsPage), findsOneWidget);
    expect(find.text('Huerto Solar'), findsOneWidget);
  });
}
