// TODO: convert to using Identifier wrapper classes

class Identifier {
  final String id;
  const Identifier({required this.id});

  @override
  String toString() {
    return id.toString();
  }
}
