import 'package:syphon/global/ids.dart';

// TODO: convert to using Identifier wrapper class
class RoomId extends Identifier {
  RoomId(id) : super(id: id);
}

enum RoomType {
  invite,
  public,
  direct,
  group,
}
