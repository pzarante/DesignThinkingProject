import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:f_clean_template/core/app_keys.dart';
import 'package:f_clean_template/features/auth/data/datasources/remote/authentication_source_service.dart';
import 'package:f_clean_template/features/auth/domain/models/authentication_user.dart';
import 'package:f_clean_template/main.dart';

import 'in_memory_preferences.dart';
import 'network_images.dart';

/// Cuenta que ya existe al arrancar cada prueba.
///
/// Su id es `me`, el mismo que usan los datos de ejemplo de las fuentes
/// locales: así es la creadora de ComicVerse y ArquiSmart y tiene perfil.
abstract final class SeededAccount {
  static const id = 'me';
  static const userName = 'mariagarcia';
  static const email = 'maria@uni.edu';
  static const password = 'Clave123!';
}

/// Arranca la app completa, como `main()`, pero con las fuentes en memoria.
///
/// Cada prueba empieza de cero: sin sesión, con los datos sembrados y con
/// solo [SeededAccount] registrada.
Future<void> startApp(WidgetTester tester) async {
  Get.reset();
  useFakeNetworkImages();

  final preferences = InMemoryPreferences();
  await AuthenticationSourceService(preferences).signUp(
    AuthenticationUser(
      id: SeededAccount.id,
      email: SeededAccount.email,
      name: SeededAccount.userName,
      password: SeededAccount.password,
    ),
  );

  registerDependencies(preferences: preferences, remote: false);
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();

  // Los avisos de GetX viven fuera del árbol de widgets: uno que siga
  // abierto al terminar haría que el `Get.back()` de la prueba siguiente
  // cerrara el aviso en vez de la pantalla.
  addTearDown(() => dismissSnackbars(tester));
}

/// Cierra los avisos de GetX que sigan en pantalla.
///
/// Van arriba y duran unos segundos: mientras están, tapan lo que quede
/// debajo (por ejemplo las pestañas del detalle al bajar hasta ellas).
Future<void> dismissSnackbars(WidgetTester tester) async {
  Get.closeAllSnackbars();
  await tester.pumpAndSettle();
}

/// Inicia sesión desde la pestaña Perfil y vuelve al inicio.
Future<void> logIn(
  WidgetTester tester, {
  String identifier = SeededAccount.email,
  String password = SeededAccount.password,
}) async {
  await tapAndSettle(tester, find.byKey(AppKeys.navProfile));
  await tapAndSettle(tester, find.byKey(AppKeys.profileLoginButton));
  expect(find.byKey(AppKeys.loginPage), findsOneWidget);

  await typeInto(tester, AppKeys.loginIdentifierField, identifier);
  await typeInto(tester, AppKeys.loginPasswordField, password);
  await tapAndSettle(tester, find.byKey(AppKeys.loginSubmitButton));
  expect(find.byKey(AppKeys.loginPage), findsNothing);

  await tapAndSettle(tester, find.byKey(AppKeys.navHome));
  expect(find.byKey(AppKeys.homePage), findsOneWidget);
}

/// Escribe [text] en el campo de [key], tocándolo primero como una persona.
///
/// Sin el toque, `enterText` escribe en el campo que tenía el foco: tras un
/// aviso de GetX (que se queda con el foco) el texto no llega a ningún lado.
Future<void> typeInto(WidgetTester tester, Key key, String text) async {
  final field = find.descendant(
    of: find.byKey(key),
    matching: find.byType(EditableText),
  );
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

/// Comprueba si el inicio enseña las secciones que solo existen con cuenta.
///
/// Baja hasta la última sección antes de mirar: el feed es una lista
/// perezosa y lo que está fuera de la pantalla no se ha construido, así que
/// "no lo encuentro" no probaría nada.
Future<void> expectAccountSections(
  WidgetTester tester, {
  required bool visible,
}) async {
  expect(find.byKey(AppKeys.homePage), findsOneWidget);
  if (visible) {
    await scrollTo(tester, find.text('Comunidades que sigues'));
    expect(find.text('Comunidades que sigues'), findsOneWidget);
  } else {
    await scrollTo(tester, find.text('Ferias y oportunidades'));
    expect(find.text('Comunidades que sigues'), findsNothing);
    expect(find.text('Mis Proyectos'), findsOneWidget); // solo la barra
  }
}

/// Toca [finder] y espera a que terminen navegación y animaciones.
///
/// Antes lo trae a la vista: en una lista larga el widget puede estar
/// construido pero fuera de la pantalla, y ahí el toque no le llega.
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Baja por la primera lista de la pantalla hasta que [finder] exista.
///
/// Sirve para lo que una `ListView` todavía no ha construido, donde
/// [WidgetTester.ensureVisible] no tiene nada que buscar.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

/// True si el botón de [key] está habilitado.
bool isEnabled(WidgetTester tester, Key key) =>
    tester.widget<ButtonStyleButton>(find.byKey(key)).onPressed != null;
