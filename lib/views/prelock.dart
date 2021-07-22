import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:syphon/context/types.dart';
import 'package:syphon/views/applock.dart';
import 'package:syphon/views/intro/lock-screen.dart';
import 'package:syphon/views/syphon.dart';

class Prelock extends StatefulWidget {
  final Widget child;
  final AppContext appContext;

  const Prelock({
    required this.child,
    required this.appContext,
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

    // permitted = widget.appContext.pinHash.isEmpty;
  }

  restart() {
    setState(() {
      key = UniqueKey();
    });
  }

  togglePermitted() {
    AppLock.of(context)?.didUnlock();
    setState(() {
      permitted = true;
    });
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(
        key: key,
        child: AppLock(
          enabled: false,
          builder: (args) => Syphon(widget.appContext),
          lockScreen: LockScreen(
            appContext: widget.appContext,
          ),
        ),
      );
}
