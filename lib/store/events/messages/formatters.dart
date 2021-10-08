import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/media/encryptor.dart';
import 'package:syphon/store/rooms/room/model.dart';

/// Format Message Content (Encrypted / Unencrypted)
///
/// It's a real shame the properties has to be fundamentally differen
/// content -> file -> url
/// vs.
/// content -> url
/// Why not just add another child object instead of changing the root parent?
///
Future<Message> formatMessageContent({
  required String tempId,
  required String userId,
  required Room room,
  required Message message,
  File? file,
  EncryptInfo? info,
}) async {
  var formatted = Message(
    id: tempId,
    url: message.url,
    body: message.body?.trimRight(),
    type: message.type,
    sender: userId,
    roomId: room.id,
    timestamp: DateTime.now().millisecondsSinceEpoch,
    pending: true,
    syncing: true,
  );

  switch (message.type) {
    case MatrixMessageTypes.image:
      {
        // Extension handling
        final fileLength = await file!.length();
        final fileImage = await decodeImageFromList(
          file.readAsBytesSync(),
        );

        var fileType = lookupMimeType(file.path);

        if (file.path.contains('HEIC')) {
          fileType = 'image/heic';
        } else if (fileType == null) {
          throw 'Unsupported Media type for a message';
        }

        if (room.encryptionEnabled) {
          // Top level content data is fundamentally different
          // with encrypted messages
          return message.copyWith(
            content: {
              'body': message.body,
              'msgtype': message.type,
              'file': {
                'url': message.url,
                'mimetype': message.type,
                'v': 'v2',
                'key': {
                  'alg': 'A256CTR',
                  'ext': true,
                  'k': info!.key,
                  'key_ops': ['encrypt', 'decrypt'],
                  'kty': 'oct'
                },
                'iv': info.iv,
                'hashes': {
                  'sha256': info.shasum, // 'fdSLu/YkRx3Wyh3KQabP3rd6+SFiKg5lsJZQHtkSAYA',
                }
              },
              'info': {
                'mimetype': 'image/jpeg',
                'h': fileImage.height,
                'w': fileImage.width,
                'size': fileLength,
                // 'thumbnail_file': {
                //   'hashes': {'sha256': '/NogKqW5bz/m8xHgFiH5haFGjCNVmUIPLzfvOhHdrxY'},
                //   'iv': 'U+k7PfwLr6UAAAAAAAAAAA',
                //   'key': {
                //     'alg': 'A256CTR',
                //     'ext': true,
                //     'k': 'RMyd6zhlbifsACM1DXkCbioZ2u0SywGljTH8JmGcylg',
                //     'key_ops': ['encrypt', 'decrypt'],
                //     'kty': 'oct'
                //   },
                //   'mimetype': 'image/jpeg',
                //   'url': 'mxc://example.org/pmVJxyxGlmxHposwVSlOaEOv',
                //   'v': 'v2'
                // },
                // 'thumbnail_info': {
                //   'h': 768,
                //   'mimetype': 'image/jpeg',
                //   'size': 211009,
                //   'w': 432,
                // },
              }
            },
          );
        }

        formatted = formatted.copyWith(content: {
          'url': message.url,
          'body': message.body,
          'msgtype': message.type,
          'info': {
            'size': fileLength,
            'mimetype': fileType,
            'w': fileImage.width,
            'h': fileImage.height,
            // 'thumbnail_info': { // TODO: handle thumbnails correctly
            //   'w': 746,
            //   'h': 600,
            //   'mimetype': fileType,
            //   'size': 56168,
            // },
            // 'xyz.amorgan.blurhash': 'LYRg0Ls:}uNaxaayNHj[^8WU9@s:',
            // 'thumbnail_url': 'mxc://matrix.org/dYEziAIojXCEoHtbwIRkKBKE'
          },
        });
        break;
      }
    case MatrixMessageTypes.text:
    default:
      {
        formatted = formatted.copyWith(content: {
          'body': message.body,
          'msgtype': message.type ?? MatrixMessageTypes.text,
        });
      }
  }

  return formatted;
}

///
/// Format Message Reply
///
/// Format a message as a reply to another
/// https://matrix.org/docs/spec/client_server/latest#rich-replies
/// https://github.com/matrix-org/matrix-doc/pull/1767
///
///
Message formatMessageReply(
  Room room,
  Message message,
  Message reply,
) {
  try {
    final body = '''> <${reply.sender}> ${reply.body}\n\n${message.body}''';
    final formattedBody =
        '''<mx-reply><blockquote><a href="https://matrix.to/#/${room.id}/${reply.id}">In reply to</a><a href="https://matrix.to/#/${reply.sender}">${reply.sender}</a><br />${reply.formattedBody ?? reply.body}</blockquote></mx-reply>${message.formattedBody ?? message.body}''';

    return message.copyWith(
      body: body,
      format: 'org.matrix.custom.html',
      formattedBody: formattedBody,
      content: {
        'body': body,
        'format': 'org.matrix.custom.html',
        'formatted_body': formattedBody,
        // m.relates_to below is not necessary in the unencrypted part of the
        // message according to the spec but Element web and android seem to
        // do it so I'm leaving it here
        'm.relates_to': {
          'm.in_reply_to': {'event_id': reply.id}
        },
        'msgtype': message.type
      },
    );
  } catch (error) {
    return message;
  }
}
