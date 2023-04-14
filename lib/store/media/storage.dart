import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/database.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/media/encryption.dart';
import 'package:syphon/store/media/model.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/user/model.dart';

///
/// Message Quesies - unencrypted (Cold Storage)
///
/// In storage, messages are indexed by eventId
/// In redux, they're indexed by RoomID and placed in a list
///
extension MediaQueries on StorageDatabase {
  Future<int> insertMedia(Media media) async {
    // HACK: temporary to account for sqlite versions without UPSERT
    if (Platform.isLinux) {
      return into(medias).insert(
        media,
        mode: InsertMode.insertOrReplace,
      );
    }
    return into(medias).insertOnConflictUpdate(media);
  }

  Future<Media?> selectMedia(String mxcUri) {
    return (select(medias)..where((tbl) => tbl.mxcUri.equals(mxcUri)))
        .getSingleOrNull();
  }

  Future<List<Media>> selectMedias(List<String?> mxcUris) {
    return (select(medias)..where((tbl) => tbl.mxcUri.isIn(List.from(mxcUris))))
        .get();
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

Future<int> saveMedia(
  String? mxcUri,
  Uint8List? data, {
  String? type,
  EncryptInfo? info,
  required StorageDatabase storage,
}) async {
  return storage.insertMedia(
    Media(mxcUri: mxcUri, data: data, info: info, type: type),
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

    log.info('[media] loaded ${images.length.toString()}');

    for (final image in images) {
      if (image.mxcUri != null && image.data != null) {
        media[image.mxcUri!] = image.data!;
      }
    }

    return media;
  } catch (error) {
    log.error(error.toString(), title: 'loadMediaAll');
    return null;
  }
}

///
/// Load All Media (Cold Storage)
///
/// load all media found within media storage
Future<Map<String, Uint8List>> loadMediaRelative({
  required StorageDatabase storage,
  List<User> users = const [],
  List<Room> rooms = const [],
  List<Message> messages = const [],
}) async {
  final media = <String, Uint8List>{};

  try {
    final idsUserAvatar = users.map((u) => u.avatarUri).toList();
    final idsRoomAvatar = rooms.map((r) => r.avatarUri).toList();
    final idsMediaMessages = messages.map((m) => m.url).toList();

    final idsAll = idsMediaMessages + idsRoomAvatar + idsUserAvatar;

    final images = await storage.selectMedias(idsAll);

    log.info('[media] loaded ${images.length.toString()}');

    for (final image in images) {
      if (image.mxcUri != null && image.data != null) {
        media[image.mxcUri!] = image.data!;
      }
    }
  } catch (error) {
    log.error(error.toString(), title: 'loadMediaRelative');
  }

  return media;
}
