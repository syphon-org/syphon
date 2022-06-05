class Identifier {
  final String id;
  const Identifier({required this.id});

  @override
  String toString() {
    return id;
  }
}

// TODO: convert to using Identifier wrapper classes
class RoomId extends Identifier {
  RoomId(id) : super(id: id);
}
