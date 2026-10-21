import 'package:flutter_test/flutter_test.dart';

import 'package:f_clean_template/core/app_keys.dart';

import '../support/test_app.dart';

void authFlowTests() {
  testWidgets('invitado -> crear pide cuenta -> clave equivocada -> correcta', (
    tester,
  ) async {
    await startApp(tester);

    // Sin sesión el inicio solo enseña lo público.
    await expectAccountSections(tester, visible: false);

    await tapAndSettle(tester, find.byKey(AppKeys.homeCreateButton));
    expect(find.byKey(AppKeys.createEntryPage), findsOneWidget);
    expect(isEnabled(tester, AppKeys.createContinueButton), isFalse);

    await tapAndSettle(tester, find.byKey(AppKeys.createOptionProject));
    await tapAndSettle(tester, find.byKey(AppKeys.createContinueButton));
    expect(find.byKey(AppKeys.loginPage), findsOneWidget);

    await typeInto(tester, AppKeys.loginIdentifierField, SeededAccount.userName);
    await typeInto(tester, AppKeys.loginPasswordField, 'Equivocada1!');
    await tapAndSettle(tester, find.byKey(AppKeys.loginSubmitButton));

    expect(find.byKey(AppKeys.loginPage), findsOneWidget);
    expect(find.text('No se pudo iniciar sesión'), findsOneWidget);

    // Con el aviso de error todavía abierto, la clave buena tiene que sacar
    // de la pantalla de login y devolver a donde se estaba.
    await typeInto(tester, AppKeys.loginPasswordField, SeededAccount.password);
    await tapAndSettle(tester, find.byKey(AppKeys.loginSubmitButton));

    expect(find.byKey(AppKeys.loginPage), findsNothing);
    expect(find.byKey(AppKeys.createEntryPage), findsOneWidget);
  });

  testWidgets('login -> perfil propio -> cerrar sesión vuelve a invitado', (
    tester,
  ) async {
    await startApp(tester);

    await tapAndSettle(tester, find.byKey(AppKeys.navProfile));
    expect(find.text('Aun no te conocemos'), findsOneWidget);
    expect(find.byKey(AppKeys.profileLogoutButton), findsNothing);

    await tapAndSettle(tester, find.byKey(AppKeys.profileLoginButton));
    await typeInto(tester, AppKeys.loginIdentifierField, SeededAccount.email);
    await typeInto(tester, AppKeys.loginPasswordField, SeededAccount.password);
    await tapAndSettle(tester, find.byKey(AppKeys.loginSubmitButton));

    // Iniciar sesión devuelve al perfil, ya con los datos de la cuenta.
    expect(find.byKey(AppKeys.profilePage), findsOneWidget);
    expect(find.text(SeededAccount.email), findsOneWidget);

    await tapAndSettle(tester, find.byKey(AppKeys.profileLogoutButton));
    await tapAndSettle(tester, find.byKey(AppKeys.profileLogoutConfirmButton));

    await expectAccountSections(tester, visible: false);
  });

  testWidgets('registro -> login con la cuenta nueva -> ya puede crear', (
    tester,
  ) async {
    await startApp(tester);

    await tapAndSettle(tester, find.byKey(AppKeys.navProfile));
    await tapAndSettle(tester, find.byKey(AppKeys.profileLoginButton));
    await tapAndSettle(tester, find.byKey(AppKeys.loginGoToSignUpButton));
    expect(find.byKey(AppKeys.signUpPage), findsOneWidget);

    // "Continuar" no se habilita hasta que la cuenta cumple las reglas.
    expect(isEnabled(tester, AppKeys.signUpSubmitButton), isFalse);
    await typeInto(tester, AppKeys.signUpUserNameField, 'nuevo.usuario');
    await typeInto(tester, AppKeys.signUpEmailField, 'nuevo@uni.edu');
    await typeInto(tester, AppKeys.signUpPasswordField, 'debil');
    expect(isEnabled(tester, AppKeys.signUpSubmitButton), isFalse);

    await typeInto(tester, AppKeys.signUpPasswordField, 'Segura123!');
    expect(isEnabled(tester, AppKeys.signUpSubmitButton), isTrue);

    await tapAndSettle(tester, find.byKey(AppKeys.signUpSubmitButton));
    expect(find.text('Cuéntanos de ti'), findsOneWidget);

    await tapAndSettle(tester, find.byKey(AppKeys.signUpSubmitButton));
    expect(find.byKey(AppKeys.signUpSuccessPage), findsOneWidget);
    expect(find.textContaining('@nuevo.usuario'), findsOneWidget);

    await tapAndSettle(tester, find.byKey(AppKeys.signUpSuccessHomeButton));
    expect(find.byKey(AppKeys.homePage), findsOneWidget);

    // La cuenta nueva sirve para entrar, también por nombre de usuario.
    await logIn(tester, identifier: 'nuevo.usuario', password: 'Segura123!');
    await expectAccountSections(tester, visible: true);

    // Con cuenta, "Crear" ya no manda a iniciar sesión.
    await tapAndSettle(tester, find.byKey(AppKeys.homeCreateButton));
    await tapAndSettle(tester, find.byKey(AppKeys.createOptionProject));
    await tapAndSettle(tester, find.byKey(AppKeys.createContinueButton));
    expect(find.byKey(AppKeys.projectWizardPage), findsOneWidget);
  });

  testWidgets('registro con un nombre de usuario tomado muestra el error', (
    tester,
  ) async {
    await startApp(tester);

    await tapAndSettle(tester, find.byKey(AppKeys.navProfile));
    await tapAndSettle(tester, find.byKey(AppKeys.profileLoginButton));
    await tapAndSettle(tester, find.byKey(AppKeys.loginGoToSignUpButton));

    await typeInto(tester, AppKeys.signUpUserNameField, SeededAccount.userName);
    await typeInto(tester, AppKeys.signUpEmailField, 'otra@uni.edu');
    await typeInto(tester, AppKeys.signUpPasswordField, 'Segura123!');
    await tapAndSettle(tester, find.byKey(AppKeys.signUpSubmitButton));
    await tapAndSettle(tester, find.byKey(AppKeys.signUpSubmitButton));

    expect(find.byKey(AppKeys.signUpPage), findsOneWidget);
    // El mensaje sale en el aviso y en el recuadro del formulario; el que se
    // queda es el del recuadro.
    expect(
      find.descendant(
        of: find.byKey(AppKeys.signUpErrorBanner),
        matching: find.text(
          'Ese nombre de usuario ya está tomado. Prueba con otro.',
        ),
      ),
      findsOneWidget,
    );
  });
}
