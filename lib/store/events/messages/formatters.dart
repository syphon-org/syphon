import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/rooms/room/model.dart';

Future<Message> formatMessageContent({
  required String tempId,
  required String userId,
  required Room room,
  required Message message,
  File? file,
}) async {
  var formatted = Message(
    id: tempId,
    url: message.url,
    body: message.body,
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
        String? fileType = lookupMimeType(file!.path);

        if (file.path.contains('HEIC')) {
          fileType = 'image/heic';
        } else if (fileType == null) {
          throw 'Unsupported Media type for a message';
        }

        // Setting up params for upload
        final int fileLength = await file.length();
        final decodedImage = await decodeImageFromList(file.readAsBytesSync());

        formatted = formatted.copyWith(content: {
          'url': message.url,
          'body': message.body,
          'msgtype': message.type,
          'info': {
            'size': fileLength,
            'mimetype': fileType,
            'w': decodedImage.width,
            'h': decodedImage.height,
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
