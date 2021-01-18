import 'package:flutter/material.dart';

class Styles {
  // Message in the middle of a users messages block
  static final bubbleBorderMiddleUser = BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(4),
    bottomLeft: Radius.circular(16),
    bottomRight: Radius.circular(4),
  );

  // Message at the beginning of a users messages block
  static final bubbleBorderTopUser = BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(16),
    bottomLeft: Radius.circular(16),
    bottomRight: Radius.circular(4),
  );

  // End of a users messages block
  static final bubbleBorderBottomUser = BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(4),
    bottomLeft: Radius.circular(16),
    bottomRight: Radius.circular(16),
  );

  // Message in the middle of a senders messages block
  static final bubbleBorderMiddleSender = BorderRadius.only(
    topLeft: Radius.circular(4),
    topRight: Radius.circular(16),
    bottomLeft: Radius.circular(4),
    bottomRight: Radius.circular(16),
  );

  // Message at the beginning of a senders messages block
  static final bubbleBorderTopSender = BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(16),
    bottomLeft: Radius.circular(4),
    bottomRight: Radius.circular(16),
  );

  // End of a sender messages block
  static final bubbleBorderBottomSender = BorderRadius.only(
    topLeft: Radius.circular(4),
    topRight: Radius.circular(16),
    bottomLeft: Radius.circular(16),
    bottomRight: Radius.circular(16),
  );
}
