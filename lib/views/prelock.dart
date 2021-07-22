import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:syphon/context/types.dart';
import 'package:syphon/views/intro/lock-screen.dart';

class Prelock extends StatefulWidget {
  final Widget child;
  final String hash;

  const Prelock({
    required this.child,
    this.hash = AppContext.DEFAULT,
  });

  static restart(BuildContext context) {
    context.findAncestorStateOfType<_PrelockState>()!.restart();
  }

  static togglePermitted(BuildContext context) {
    context.findAncestorStateOfType<_PrelockState>()!.togglePermitted();
  }

  @override
  _PrelockState createState() => _PrelockState();
}

class _PrelockState extends State<Prelock> {
  Key key = UniqueKey();
  bool permitted = false;

  @override
  void initState() {
    super.initState();

    permitted = widget.hash.isEmpty;
  }

  restart() {
    setState(() {
      key = UniqueKey();
    });
  }

  togglePermitted() {
    setState(() {
      permitted = !permitted;
    });
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(
        key: key,
        child: permitted
            ? widget.child
            : MaterialApp(
                home: LockScreen(
                  hash: widget.hash,
                ),
              ),
      );
}
