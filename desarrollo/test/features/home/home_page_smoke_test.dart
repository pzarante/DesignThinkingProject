import 'package:f_clean_template/core/widgets/app_section_header.dart';
import 'package:f_clean_template/features/auth/domain/models/authentication_user.dart';
import 'package:f_clean_template/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:f_clean_template/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:f_clean_template/features/home/data/datasources/local/local_home_source.dart';
import 'package:f_clean_template/features/home/data/repositories/home_repository.dart';
import 'package:f_clean_template/features/home/domain/repositories/i_home_repository.dart';
import 'package:f_clean_template/features/home/ui/viewmodels/home_controller.dart';
import 'package:f_clean_template/features/home/ui/views/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _StubAuthRepository implements IAuthRepository {
  @override
  Future<AuthenticationUser?> getLoggedUser() async =>
      AuthenticationUser(email: 'maria@uni.edu', name: 'María', password: 'x');

  @override
  Future<bool> restoreSession() async => true;

  @override
  Future<bool> login(AuthenticationUser user) async => true;

  @override
  Future<bool> signUp(AuthenticationUser user) async => true;

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
  bool get isAnonymous => false;

  @override
  Future<AuthenticationUser> ensureGuestSession() async =>
      AuthenticationUser(email: 'maria@uni.edu', name: 'María');
}

void main() {
  testWidgets('HomePage renders every feed section', (tester) async {
    // El feed es una `ListView`: en la pantalla por defecto de las pruebas
    // las últimas secciones ni se construyen, y no se puede afirmar nada
    // sobre ellas.
    // Estrecha y muy alta: a lo ancho las portadas 16:9 crecen, y el
    // feed entero se sale de cualquier alto razonable.
    tester.view.physicalSize = const Size(400, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Get.testMode = true;
    Get.put<IHomeRepository>(HomeRepository(LocalHomeSource()));
    Get.put(HomeController(Get.find()));
    Get.put(AuthenticationController(_StubAuthRepository()));

    await tester.pumpWidget(const GetMaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    expect(find.text('Innovation Hub'), findsOneWidget);
    expect(find.text('Comunidades que sigues'), findsOneWidget);
    expect(find.text('Studio Creativo UNI'), findsOneWidget);
    expect(find.text('Recomendado para ti'), findsOneWidget);
    // La tarjeta enseña la etiqueta y la etapa como dos chips, no como una
    // línea "Tecnología • Investigación" (así era un diseño anterior).
    expect(find.text('TECNOLOGÍA'), findsWidgets);
    expect(find.text('INVESTIGACIÓN'), findsWidgets);
    expect(find.text('Ferias y oportunidades'), findsOneWidget);
    expect(find.text('Crear'), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);

    // Con la pantalla alta ya no hace falta desplazarse: todo el feed está
    // construido.
    expect(find.text('15 proyectos participando'), findsOneWidget);
    expect(
      find.widgetWithText(AppSectionHeader, 'Mis Proyectos'),
      findsOneWidget,
    );
    expect(find.text('MotionLab'), findsOneWidget);
    expect(find.text('3 Integrantes'), findsOneWidget);

    Get.reset();
  });
}
