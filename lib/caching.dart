import 'package:shared_preferences/shared_preferences.dart';

getCachedData(key) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(key) ?? 0;
}

setCacheData(key, value) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString(key, value);
}

removeCacheData(key) async {
  final prefs = await SharedPreferences.getInstance();

  if (getCachedData(key) != 0) {
    prefs.remove(key);
  }
}
