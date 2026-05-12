import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  var username = Uri.encodeComponent('enseignant');
  var res = await http.get(Uri.parse(
    'http://193.111.250.244:3046/api/reservations'
    '?filters[organizer_name][\$eq]=$username'
    '&populate=space&sort=createdAt:desc'
  ));
  var body = jsonDecode(res.body);
  var data = body['data'] as List;
  print('Status: ${res.statusCode}');
  print('Found: ${data.length} reservations');
  if (data.isNotEmpty) {
    print('First: start=${data[0]['start_datetime']}, space=${data[0]['space']?['name']}');
  }
}
