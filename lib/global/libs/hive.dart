import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

const TETHER_HIVE_ENCRYPTION_KEY = 'tether@hivekey';
const TETHER_HIVE_KEY = 'tether';

Future initStorage() async {
  var appStorageLocation = await getApplicationDocumentsDirectory();
  Hive.init(appStorageLocation.path);

  final storage = new FlutterSecureStorage();
  final encryptionKey = Hive.generateSecureKey();
  print(encryptionKey);
  print(encryptionKey.toString());

  await storage.write(
      key: TETHER_HIVE_ENCRYPTION_KEY, value: jsonEncode(encryptionKey));
  return await Hive.openBox(TETHER_HIVE_KEY, encryptionKey: encryptionKey);
}

Future getStorage() async {
  final storage = new FlutterSecureStorage();
  var encryptionKeySerialized =
      await storage.read(key: TETHER_HIVE_ENCRYPTION_KEY);

  List<int> encryptionKey = jsonDecode(encryptionKeySerialized);
  return await Hive.openBox('tether@hive', encryptionKey: encryptionKey);
}
