import 'package:f_clean_template/core/app_keys.dart';
import 'package:f_clean_template/features/auth/domain/models/authentication_user.dart';
import 'package:f_clean_template/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:f_clean_template/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:f_clean_template/features/auth/ui/views/login_page.dart';
import 'package:f_clean_template/features/auth/ui/views/signup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'support/fake_network_images.dart';

// ---------------------------------------------------------------------------
// Repositorio falso reutilizable en todos los tests de este archivo.
// ---------------------------------------------------------------------------

/// Repositorio que acepta solo las credenciales de prueba.
class _FakeAuthRepository implements IAuthRepository {
  final String validEmail = 'a@a.com';
  final String validPassword = '123456';

  @override
  final bool isAnonymous = false;

  @override
  Future<AuthenticationUser?> getLoggedUser() async =>
      AuthenticationUser(email: validEmail, name: 'Test User');

  @override
  Future<bool> restoreSession() async => false;

  @override
  Future<bool> login(AuthenticationUser user) async =>
      user.email == validEmail && user.password == validPassword;

  @override
  Future<bool> signUp(AuthenticationUser user) async =>
      user.email.contains('@') && (user.password?.length ?? 0) >= 6;

  @override
  Future<bool> isUserNameAvailable(String userName) async => true;

  @override
  Future<bool> logOut() async => true;

  @override
  Future<bool> validate(String email, String validationCode) async => true;

  @override
  Future<bool> validateToken() async => true;

  @override
  Future<void> forgotPassword(String email) async {}

  @override
  Future<AuthenticationUser> ensureGuestSession() async =>
      AuthenticationUser(email: validEmail, name: 'Guest');
}

// ---------------------------------------------------------------------------
// Helper: monta LoginPage empujada sobre una Home, de modo que Get.back()
// pueda sacarla del árbol cuando el login es exitoso.
// ---------------------------------------------------------------------------
Future<void> _pumpLogin(WidgetTester tester) async {
  useFakeNetworkImages();
  Get.testMode = true;
  Get.put<IAuthRepository>(_FakeAuthRepository());
  Get.put(AuthenticationController(Get.find()));
  await tester.pumpWidget(GetMaterialApp(
    initialRoute: '/',
    getPages: [
      GetPage(
        name: '/',
        page: () => const Scaffold(body: Center(child: Text('Inicio'))),
      ),
      GetPage(name: '/login', page: () => const LoginPage()),
    ],
  ));
  Get.toNamed('/login');
  await tester.pumpAndSettle();
}

Future<void> _drainSnackbar(WidgetTester tester) async {
  if (Get.isSnackbarOpen) {
    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  tearDown(() => Get.reset());

  // ── Login ──────────────────────────────────────────────────────────────────

  testWidgets('Widget login validación @ email', (WidgetTester tester) async {
    await _pumpLogin(tester);

    await tester.enterText(find.byKey(AppKeys.loginIdentifierField), 'a.com');
    await tester.enterText(find.byKey(AppKeys.loginPasswordField), '123456');
    await tester.tap(find.byKey(AppKeys.loginSubmitButton));
    await tester.pumpAndSettle();

    // El controller rechaza porque falta @; la pantalla sigue visible.
    expect(find.byKey(AppKeys.loginPage), findsOneWidget);
    await _drainSnackbar(tester);
  });

  testWidgets('Widget login validación campo vacío email',
      (WidgetTester tester) async {
    await _pumpLogin(tester);

    await tester.enterText(find.byKey(AppKeys.loginPasswordField), '123456');
    await tester.tap(find.byKey(AppKeys.loginSubmitButton));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.loginPage), findsOneWidget);
    await _drainSnackbar(tester);
  });

  testWidgets('Widget login validación número de caracteres password',
      (WidgetTester tester) async {
    await _pumpLogin(tester);

    await tester.enterText(find.byKey(AppKeys.loginIdentifierField), 'a@a.com');
    await tester.enterText(find.byKey(AppKeys.loginPasswordField), '123');
    await tester.tap(find.byKey(AppKeys.loginSubmitButton));
    await tester.pumpAndSettle();

    // La contraseña no coincide con la válida → el repo devuelve false.
    expect(find.byKey(AppKeys.loginPage), findsOneWidget);
    await _drainSnackbar(tester);
  });

  testWidgets('Widget login validación campo vacío password',
      (WidgetTester tester) async {
    await _pumpLogin(tester);

    await tester.enterText(find.byKey(AppKeys.loginIdentifierField), 'a@a.com');
    await tester.tap(find.byKey(AppKeys.loginSubmitButton));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.loginPage), findsOneWidget);
    await _drainSnackbar(tester);
  });

  testWidgets('Widget login autenticación exitosa',
      (WidgetTester tester) async {
    await _pumpLogin(tester);

    await tester.enterText(find.byKey(AppKeys.loginIdentifierField), 'a@a.com');
    await tester.enterText(find.byKey(AppKeys.loginPasswordField), '123456');
    await tester.tap(find.byKey(AppKeys.loginSubmitButton));
    await tester.pumpAndSettle();

    // LoginPage desaparece del árbol cuando el login es exitoso.
    expect(find.byKey(AppKeys.loginPage), findsNothing);
  });

  testWidgets('Widget login autenticación no exitosa',
      (WidgetTester tester) async {
    await _pumpLogin(tester);

    await tester.enterText(find.byKey(AppKeys.loginIdentifierField), 'b@a.com');
    await tester.enterText(find.byKey(AppKeys.loginPasswordField), '12345');
    await tester.tap(find.byKey(AppKeys.loginSubmitButton));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.loginPage), findsOneWidget);
    await _drainSnackbar(tester);
  });

  // ── SignUp ─────────────────────────────────────────────────────────────────

  testWidgets('Widget signUp validación email', (WidgetTester tester) async {
    useFakeNetworkImages();
    Get.testMode = true;
    Get.put<IAuthRepository>(_FakeAuthRepository());
    Get.put(AuthenticationController(Get.find()));
    await tester.pumpWidget(const GetMaterialApp(home: SignUpPage()));
    await tester.pumpAndSettle();

    // Email sin @ → el controller rechaza en el paso 1.
    await tester.enterText(find.byKey(AppKeys.signUpEmailField), 'invalido');
    await tester.enterText(find.byKey(AppKeys.signUpPasswordField), 'Abc123!');
    await tester.tap(find.byKey(AppKeys.signUpSubmitButton));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.signUpPage), findsOneWidget);
  });

  testWidgets('Widget signUp validación password', (WidgetTester tester) async {
    useFakeNetworkImages();
    Get.testMode = true;
    Get.put<IAuthRepository>(_FakeAuthRepository());
    Get.put(AuthenticationController(Get.find()));
    await tester.pumpWidget(const GetMaterialApp(home: SignUpPage()));
    await tester.pumpAndSettle();

    // Contraseña demasiado corta → el controller rechaza.
    await tester.enterText(find.byKey(AppKeys.signUpEmailField), 'a@a.com');
    await tester.enterText(find.byKey(AppKeys.signUpPasswordField), '123');
    await tester.tap(find.byKey(AppKeys.signUpSubmitButton));
    await tester.pumpAndSettle();
 
    expect(find.byKey(AppKeys.signUpPage), findsOneWidget);
  });
}