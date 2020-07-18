import 'package:syphon/global/dimensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AlertProvider extends StatefulWidget {
  final Widget child;

  AlertProvider({
    Key key,
    this.child,
  }) : super(key: key);

  @override
  AlertProviderState createState() => AlertProviderState();
}

/**
 * RoundedPopupMenu
 * Mostly an example for myself on how to override styling or other options on
 * existing components app wide
 */
class AlertProviderState extends State<AlertProvider> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: null,
        body: widget.child,
      );
}
