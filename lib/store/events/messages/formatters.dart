import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/media/converters.dart';
import 'package:syphon/store/media/encryption.dart';
import 'package:syphon/store/rooms/room/model.dart';

///
/// Format Message Content (Encrypted / Unencrypted)
///
/// A real shame the content properties have to be fundamentally different
/// between encrypted and unencrypted media messages
/// content -> file -> url
/// vs.
/// content -> url
/// Why not just add another child object instead of changing the root parent?
/// makes it difficult to encode and decode
///
/// https://matrix.org/docs/spec/client_server/latest#sending-encrypted-attachments
///
Future<Message> formatMessageContent({
  required String tempId,
  required String userId,
  required Room room,
  required Message message,
  Message? related,
  bool edit = false,
  EncryptInfo? info = const EncryptInfo(),
  File? file,
}) async {
  final formatted = Message(
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

        final mimeTypeOption = lookupMimeType(file.path);
        final mimeType = convertMimeTypes(file, mimeTypeOption);

        // TODO: handle a thumbnail file and content
        // final thumbnailContent = {
        //   'w': 746,
        //   'h': 600,
        //   'mimetype': fileType,
        //   'size': 56168,
        // };

        if (room.encryptionEnabled) {
          if (info!.key == null || info.iv == null) {
            throw 'Cannot send encrypted media message without providing decryption info';
          }

          // must be unpadded url safe per spec, so replacing the pad with nothing
          final iv = info.iv!.replaceAll('=', '');
          final shasum = info.shasum?.replaceAll('=', '');
          final key = base64Url.encode(info.keyToBytes()).replaceAll('=', '');

          final fileContent = {
            'url': message.url,
            'mimetype': message.type,
            'v': 'v2',
            'key': {
              'alg': 'A256CTR',
              'ext': true,
              'k': key,
              'key_ops': ['encrypt', 'decrypt'],
              'kty': 'oct'
            },
            'iv': iv,
            'hashes': {
              'sha256': shasum,
            }
          };

          final thumbnailContent = {
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
          };

          // Top level content data is fundamentally different
          // with encrypted messages
          return formatted.copyWith(
            file: fileContent,
            content: {
              'body': message.body,
              'msgtype': message.type,
              'file': fileContent,
              'info': {
                'mimetype': mimeType,
                'h': fileImage.height,
                'w': fileImage.width,
                'size': fileLength,
                ...thumbnailContent,
              }
            },
          );
        }

        return formatted.copyWith(content: {
          'url': message.url,
          'body': message.body,
          'msgtype': message.type,
          'info': {
            'size': fileLength,
            'mimetype': mimeType,
            'w': fileImage.width,
            'h': fileImage.height,
            // TODO: 'thumbnail_info': thumbnailContent
            // 'xyz.amorgan.blurhash': 'LYRg0Ls:}uNaxaayNHj[^8WU9@s:',
            // 'thumbnail_url': 'mxc://matrix.org/dYEziAIojXCEoHtbwIRkKBKE'
          },
        });
      }
    case MatrixMessageTypes.text:
    default:
      {
        if (edit && related != null) {
          return formatted.copyWith(content: {
            'body': '* ${message.body}',
            'msgtype': message.type ?? MatrixMessageTypes.text,
            'm.new_content': {
              'body': message.body,
              'msgtype': MatrixMessageTypes.text,
            },
            'm.relates_to': {
              'event_id': related.id,
              'rel_type': RelationTypes.replace,
            }
          });
        }

        return formatted.copyWith(content: {
          'body': message.body,
          'msgtype': message.type ?? MatrixMessageTypes.text,
        });
      }
  }
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
