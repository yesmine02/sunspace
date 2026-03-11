import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

void main() async {
  try {
    // Read the shared prefs file where the app dumps data
    // On windows, flutter shared prefs are in the user profile or roaming.
    // Instead of HTTP, let me just find the shared pref file!
    final dir = Directory(Platform.environment['USERPROFILE']! + '\\AppData');
    var files = dir.listSync(recursive: true).where((f) => f.path.contains('debug_users_dump'));
    for (var f in files) {
      print('Found: ${f.path}');
    }
  } catch(e) {
    print(e);
  }
}
