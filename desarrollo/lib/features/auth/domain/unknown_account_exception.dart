/// No existe ninguna cuenta con el nombre de usuario escrito.
///
/// Es distinto de una contraseña equivocada: ahí decide ROBLE y responde un
/// 401. Aquí ni siquiera se llega a pedirle nada, porque el nombre de usuario
/// hay que traducirlo a un correo antes y no hubo a qué traducirlo.
///
/// `errorMessage` no la conoce y cae en su `toString()`, así que este mensaje
/// es el que ve la persona.
class UnknownAccountException implements Exception {
  const UnknownAccountException(this.message);

  final String message;

  @override
  String toString() => message;
}
