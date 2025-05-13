//BECHA
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<List<dynamic>> fetchNews() async {
  final response =
      await http.get(Uri.parse('http://172.20.10.3:3000/news/latest'));

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load news');
  }
}
