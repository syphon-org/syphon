// Package imports:
import 'package:http/http.dart' as http;

var httpClient;

Future<void> initHttpClient() async {
  httpClient = http.Client;
}
