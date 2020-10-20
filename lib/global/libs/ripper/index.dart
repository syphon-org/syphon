import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syphon/global/libs/hive/index.dart';
import 'package:syphon/store/auth/state.dart';
// Project imports:
import 'package:syphon/global/libs/hive/index.dart';
import 'package:syphon/store/crypto/state.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/media/state.dart';
import 'package:syphon/store/rooms/state.dart';
import 'package:syphon/store/settings/state.dart';
import 'package:syphon/store/sync/state.dart';
import 'package:syphon/store/user/state.dart';

/** 
 * 
 * Ripper API (temp)
 *  
 * One way convertion of the Hive cache to a manually encrypted / encoded state cache
 */
class Ripper {
  static Future<dynamic> encodeHive(AppState state) async {
    try {
      Cache.state.put(
        state.syncStore.runtimeType.toString(),
        state.syncStore,
      );
      // debugPrint('[Hive Storage] caching syncStore');
    } catch (error) {
      debugPrint('[Hive Serializer Encode] $error');
    }

    try {
      Cache.stateRooms.put(
        state.roomStore.runtimeType.toString(),
        state.roomStore,
      );
      // debugPrint('[Hive Storage] caching roomStore');
    } catch (error) {
      debugPrint('[Hive Serializer Encode] $error');
    }

    try {
      Cache.state.put(
        state.mediaStore.runtimeType.toString(),
        state.mediaStore,
      );
      // debugPrint('[Hive Storage] caching mediaStore');
    } catch (error) {
      debugPrint('[Hive Serializer Encode] $error');
    }

    try {
      Cache.state.put(
        state.settingsStore.runtimeType.toString(),
        state.settingsStore,
      );
      // debugPrint('[Hive Storage] caching settingsStore');
    } catch (error) {
      debugPrint('[Hive Serializer Encode] $error');
    }

    try {
      Cache.state.put(
        state.cryptoStore.runtimeType.toString(),
        state.cryptoStore,
      );
      // debugPrint('[Hive Storage] caching cryptoStore');
    } catch (error) {
      debugPrint('[Hive Serializer Encode] $error');
    }
  }

  static Future<dynamic> decodeHive() async {
    AuthStore authStoreConverted = AuthStore();
    SyncStore syncStoreConverted = SyncStore();
    CryptoStore cryptoStoreConverted = CryptoStore();
    MediaStore mediaStoreConverted = MediaStore();
    RoomStore roomStoreConverted = RoomStore();
    SettingsStore settingsStoreConverted = SettingsStore();
    UserStore userStore = UserStore();

    try {
      authStoreConverted = Cache.state.get(
        authStoreConverted.runtimeType.toString(),
        defaultValue: null,
      );
    } catch (error) {
      debugPrint('[Hive Serializer Decode] $error');
    }

    try {
      syncStoreConverted = Cache.state.get(
        syncStoreConverted.runtimeType.toString(),
        defaultValue: null,
      );
    } catch (error) {
      debugPrint('[Hive Serializer Decode] $error');
    }

    try {
      cryptoStoreConverted = Cache.state.get(
        cryptoStoreConverted.runtimeType.toString(),
        defaultValue: null,
      );
    } catch (error) {
      debugPrint('[Hive Serializer Decode] $error');
    }

    try {
      roomStoreConverted = Cache.stateRooms.get(
        roomStoreConverted.runtimeType.toString(),
        defaultValue: null,
      );
    } catch (error) {
      debugPrint('[Hive Serializer Decode] $error');
    }

    try {
      mediaStoreConverted = Cache.state.get(
        mediaStoreConverted.runtimeType.toString(),
        defaultValue: null,
      );
    } catch (error) {
      debugPrint('[Hive Serializer Decode] $error');
    }

    try {
      settingsStoreConverted = Cache.state.get(
        settingsStoreConverted.runtimeType.toString(),
        defaultValue: null,
      );
    } catch (error) {
      debugPrint('[Hive Serializer Decode] $error');
    }
  }

  static Future<dynamic> convertToManual() async {}
}
