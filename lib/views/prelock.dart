import 'package:flutter/widgets.dart';

class Prelock extends StatefulWidget {
  final Widget child;

  const Prelock({required this.child});

  static restart(BuildContext context) {
    context.findAncestorStateOfType<_PrelockState>()!.restart();
  }

  @override
  _PrelockState createState() => _PrelockState();
}

class _PrelockState extends State<Prelock> {
  Key key = UniqueKey();

  restart() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(
        key: key,
        child: widget.child,
      );
}
