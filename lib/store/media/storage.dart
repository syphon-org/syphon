import 'dart:async';
import 'dart:typed_data';

import 'package:moor/moor.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/moor/database.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/media/encryption.dart';
import 'package:syphon/store/media/model.dart';
import 'package:syphon/store/rooms/room/model.dart';

///
/// Message Quesies - unencrypted (Cold Storage)
///
/// In storage, messages are indexed by eventId
/// In redux, they're indexed by RoomID and placed in a list
///
extension MediaQueries on StorageDatabase {
  Future<void> insertMedia(Media media) {
    return into(medias).insertOnConflictUpdate(media);
  }

  Future<Media?> selectMedia(String mxcUri) {
    return (select(medias)..where((tbl) => tbl.mxcUri.equals(mxcUri))).getSingleOrNull();
  }

  Future<List<Media>> selectMedias(List<String?> mxcUris) {
    return (select(medias)..where((tbl) => tbl.mxcUri.isIn(mxcUris))).get();
  }

  Future<List<Media>> selectMediaAll() {
    return (select(medias)).get();
  }
}

Future<bool> checkMedia(
  String? mxcUri, {
  required StorageDatabase storage,
}) async {
  if (mxcUri == null) return false;
  return (await storage.selectMedia(mxcUri)) != null;
}

Future<void> saveMedia(
  String? mxcUri,
  Uint8List? data, {
  EncryptInfo? info,
  required StorageDatabase storage,
}) async {
  return storage.insertMedia(
    Media(data: data, mxcUri: mxcUri, info: info),
  );
}

/// Load Media (Cold Storage)
///
/// load one set of media data based on mxc uri
Future<Media?> loadMedia({
  String? mxcUri,
  required StorageDatabase storage,
}) async {
  if (mxcUri == null) return null;
  return storage.selectMedia(mxcUri);
}

///
/// Load All Media (Cold Storage)
///
/// load all media found within media storage
Future<Map<String, Uint8List>?> loadMediaAll({
  required StorageDatabase storage,
}) async {
  try {
    final Map<String, Uint8List> media = {};

    final images = await storage.selectMediaAll();

    printInfo('[media] loaded ${images.length.toString()}');

    for (final image in images) {
      if (image.mxcUri != null && image.data != null) {
        media[image.mxcUri!] = image.data!;
      }
    }

    return media;
  } catch (error) {
    printError(error.toString(), title: 'loadMediaAll');
    return null;
  }
}

///
/// Load All Media (Cold Storage)
///
/// load all media found within media storage
Future<Map<String, Uint8List>?> loadMediaRelative({
  required StorageDatabase storage,
  List<Message>? messages,
  List<Room>? rooms,
}) async {
  try {
    final Map<String, Uint8List> media = {};

    final mediaIds = <String>[];

    final images = await storage.selectMedias(mediaIds);

    printInfo('[media] loaded ${images.length.toString()}');

    for (final image in images) {
      if (image.mxcUri != null && image.data != null) {
        media[image.mxcUri!] = image.data!;
      }
    }

    return media;
  } catch (error) {
    printError(error.toString(), title: 'loadMediaRelative');
    return null;
  }
}
