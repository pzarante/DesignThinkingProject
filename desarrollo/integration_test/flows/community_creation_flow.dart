import 'package:flutter_test/flutter_test.dart';

import 'package:f_clean_template/core/app_keys.dart';

import '../support/test_app.dart';

void communityCreationFlowTests() {
  testWidgets('crear comunidad vinculando un proyecto -> aparece en el inicio', (
    tester,
  ) async {
    await startApp(tester);
    await logIn(tester);

    await tapAndSettle(tester, find.byKey(AppKeys.homeCreateButton));
    await tapAndSettle(tester, find.byKey(AppKeys.createOptionCommunity));
    await tapAndSettle(tester, find.byKey(AppKeys.createContinueButton));
    expect(find.byKey(AppKeys.communityFormPage), findsOneWidget);

    // Hacen falta un nombre y al menos un proyecto.
    expect(isEnabled(tester, AppKeys.communitySubmitButton), isFalse);
    await typeInto(tester, AppKeys.communityNameField, 'Club de Robótica');
    expect(isEnabled(tester, AppKeys.communitySubmitButton), isFalse);

    await scrollTo(tester, find.byKey(AppKeys.communityPickProjectsButton));
    await tapAndSettle(tester, find.byKey(AppKeys.communityPickProjectsButton));
    expect(find.text('Vincular proyectos'), findsOneWidget);
    await tapAndSettle(tester, find.text('MotionLab'));
    await tapAndSettle(
      tester,
      find.byKey(AppKeys.communityPickerConfirmButton),
    );

    // El proyecto elegido queda como chip en el formulario.
    expect(find.text('MotionLab'), findsOneWidget);
    expect(isEnabled(tester, AppKeys.communitySubmitButton), isTrue);
    await tapAndSettle(tester, find.byKey(AppKeys.communitySubmitButton));

    expect(find.byKey(AppKeys.communityCreatedPage), findsOneWidget);
    expect(find.text('¡Comunidad creada!'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(AppKeys.communityCreatedHomeButton));

    // Quien la crea la sigue: sale primera en "Comunidades que sigues".
    await expectAccountSections(tester, visible: true);
    await scrollTo(tester, find.text('Club de Robótica'));
    expect(find.text('Club de Robótica'), findsOneWidget);
  });
}
