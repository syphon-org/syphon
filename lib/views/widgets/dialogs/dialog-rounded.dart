import 'package:flutter/material.dart';

class DialogRounded extends StatefulWidget {
  const DialogRounded({
    Key? key,
    this.title = '',
    this.content = '',
    this.children = const <Widget>[],
  }) : super(key: key);

  final String title;
  final String content;
  final List<Widget> children;

  @override
  _DialogTextInputState createState() => _DialogTextInputState();
}

class _DialogTextInputState extends State<DialogRounded> {
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double defaultWidgetScaling = width * 0.725;

    return SimpleDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titlePadding: EdgeInsets.only(
        left: 24,
        right: 16,
        top: 16,
        bottom: 16,
      ),
      contentPadding: EdgeInsets.only(
        // left: 16,
        // right: 16,
        bottom: 16,
      ),
      title: Text(widget.title),
      children: <Widget>[
        SizedBox(
          width: defaultWidgetScaling,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.children,
          ),
        )
      ],
    );
  }
}
