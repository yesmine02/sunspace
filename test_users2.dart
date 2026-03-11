import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('http://193.111.250.244:3046/api/users?populate=*');
  final response = await http.get(url, headers: {'Accept': 'application/json'});
  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    var filtered = [];
    for (var u in data) {
      if (u['username'] == 'intern' || u['username'] == 'association_member') {
        filtered.add(u);
      }
    }
    File('output.json').writeAsStringSync(jsonEncode(filtered));
  }
}
