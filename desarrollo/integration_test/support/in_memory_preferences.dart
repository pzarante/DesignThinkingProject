import 'package:f_clean_template/core/i_local_preferences.dart';

/// Preferencias que viven solo mientras dura la prueba.
///
/// Las reales escriben en disco (o en el llavero del sistema), así que una
/// cuenta creada en una prueba seguiría ahí en la siguiente y el orden de
/// ejecución cambiaría el resultado.
class InMemoryPreferences implements ILocalPreferences {
  final Map<String, Object> _values = {};

  @override
  Future<String?> getString(String key) async => _values[key] as String?;

  @override
  Future<void> setString(String key, String value) async =>
      _values[key] = value;

  @override
  Future<int?> getInt(String key) async => _values[key] as int?;

  @override
  Future<void> setInt(String key, int value) async => _values[key] = value;

  @override
  Future<double?> getDouble(String key) async => _values[key] as double?;

  @override
  Future<void> setDouble(String key, double value) async =>
      _values[key] = value;

  @override
  Future<bool?> getBool(String key) async => _values[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async => _values[key] = value;

  @override
  Future<List<String>?> getStringList(String key) async =>
      _values[key] as List<String>?;

  @override
  Future<void> setStringList(String key, List<String> value) async =>
      _values[key] = List.of(value);

  @override
  Future<void> remove(String key) async => _values.remove(key);

  @override
  Future<void> clear() async => _values.clear();
}
