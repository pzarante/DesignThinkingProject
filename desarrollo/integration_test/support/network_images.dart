// Portadas falsas donde hay `dart:io` (móvil y escritorio).
//
// En web no hay `HttpOverrides`: las imágenes las pide el navegador y no se
// pueden interceptar desde Dart, así que ahí no se hace nada.
export 'network_images_web.dart'
    if (dart.library.io) '../../test/support/fake_network_images.dart';
