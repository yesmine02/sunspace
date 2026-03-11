import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('http://193.111.250.244:3046/api/users?populate=*');
  final response = await http.get(url, headers: {'Accept': 'application/json'});
  if (response.statusCode == 200) {
    try {
      dynamic data = jsonDecode(response.body);
      List<dynamic> users = (data is Map && data.containsKey('data')) ? data['data'] : data;
      var filtered = [];
      for (var u in users) {
        if (u['username'] == 'intern' || u['username'] == 'association_member') {
          filtered.add(u);
        }
      }
      print(jsonEncode(filtered));
    } catch(e) {
      print(e);
    }
  }
}
