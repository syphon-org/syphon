import 'dart:convert';

import 'package:syphon/global/libs/matrix/encryption.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/events/model.dart';
import 'package:canonical_json/canonical_json.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:olm/olm.dart' as olm;

/**
 * Encrypt event content with loaded outbound session for room
 * 
 * https://matrix.org/docs/guides/end-to-end-encryption-implementation-guide#sending-an-encrypted-message-event
 */
ThunkAction<AppState> encryptMessageContent({
  String roomId,
  String eventType = EventTypes.message,
  Map content,
}) {
  return (Store<AppState> store) async {
    // Load and deserialize session
    final olm.OutboundGroupSession outboundMessageSession = store.dispatch(
      loadOutboundMessageSession(roomId: roomId),
    );

    // Create payload for encryption per spe
    final payload = {
      'type': eventType,
      'content': content,
      'room_id': roomId,
    };

    // Canoncially encode the json for encryption
    final encodedPayload = canonicalJson.encode(payload);
    final serializedPayload = utf8.decode(encodedPayload);
    final encryptedPayload = outboundMessageSession.encrypt(serializedPayload);
    print('[encryptMessageContent] $encryptedPayload');

    // Save the outbound session after processing content
    await store.dispatch(saveOutboundMessageSession(
      roomId: roomId,
      session: outboundMessageSession.pickle(roomId),
    ));

    // Pull identity keys out of olm account
    final olmAccount = store.state.cryptoStore.olmAccount;
    final keys = json.decode(olmAccount.identity_keys());

    // Return the content to be sent or processed
    return {
      'sender_key': keys[Algorithms.curve25591],
      'ciphertext': encryptedPayload,
      'session_id': outboundMessageSession.session_id()
    };
  };
}

/**
 * Encrypt event content with loaded outbound session for a device
 * 
 * NOTE: Utilizes available one time keys pre-fetched 
 * and claimed by the current user
 * 
 * https://matrix.org/docs/spec/client_server/latest#m-room-encrypted
 */
ThunkAction<AppState> encryptKeyContent({
  String roomId,
  String identityKey,
  String eventType = EventTypes.roomKey,
  Map content,
}) {
  return (Store<AppState> store) async {
    // Create payload for encryption per spe
    final payload = {
      'type': eventType,
      'content': content,
      'room_id': roomId,
    };

    // All olm sessions should already be created
    // before sending a room key event to devices
    // Load and deserialize session
    final olm.Session outboundKeySession = await store.dispatch(
      loadKeySession(identityKey: identityKey),
    );

    // Canoncially encode the json for encryption
    final encodedPayload = canonicalJson.encode(payload);
    final serializedPayload = utf8.decode(encodedPayload);
    final encryptedPayload = outboundKeySession.encrypt(serializedPayload);

    // Save the outbound session after processing content
    await store.dispatch(saveOutboundKeySession(
      identityKey: identityKey,
      session: outboundKeySession.pickle(roomId),
    ));

    // Pull identity keys out of olm account
    final olmAccount = store.state.cryptoStore.olmAccount;
    final keys = json.decode(olmAccount.identity_keys());

    // Return the content to be sent or processed
    if (encryptedPayload.type == 0) {
      return {
        'sender_key': keys[Algorithms.curve25591],
        'ciphertext': {
          'body': encryptedPayload.body,
          'type': encryptedPayload.type,
        },
        'session_id': outboundKeySession.session_id()
      };
    }

    return {
      'sender_key': keys[Algorithms.curve25591],
      'ciphertext': encryptedPayload.body,
      'session_id': outboundKeySession.session_id()
    };
  };
}

/**
 * Decrypting toDevice event content with loaded 
 * key session (outbound | inbound) for that device
 * 
 * NOTE: Utilizes available one time keys pre-fetched 
 * and claimed by the current user
 * 
 * https://matrix.org/docs/spec/client_server/latest#m-room-encrypted
 */
ThunkAction<AppState> decryptKeyContent({
  Map content,
}) {
  return (Store<AppState> store) async {
    final deviceKeysOwned = store.state.cryptoStore.deviceKeysOwned;
    final currentDeviceKey =
        deviceKeysOwned[store.state.authStore.user.deviceId];

    // Extract the payload meant for this device by identity
    final String identityKey = content['sender_key'];
    final Map<String, String> ciphertextContent =
        content['ciphertext'][currentDeviceKey];

    // Load and deserialize or create session
    final olm.Session keySession = store.dispatch(
      loadKeySession(
        identityKey: identityKey,
        type: ciphertextContent['type'],
        body: ciphertextContent['body'],
      ),
    );

    // Decrypt the payload with the session for device identity
    final decryptedPayload = keySession.decrypt(
      int.parse(ciphertextContent['type']),
      ciphertextContent['body'],
    );

    // Return the content to be sent or processed
    return json.decode(decryptedPayload);
  };
}
