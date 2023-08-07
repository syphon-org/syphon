import 'package:flutter/material.dart';

class DialogRounded extends StatelessWidget {
  const DialogRounded({
    super.key,
    this.title = '',
    this.content = '',
    this.children = const <Widget>[],
  });

  final String title;
  final String content;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double defaultWidgetScaling = width * 0.725;

    return SimpleDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titlePadding: const EdgeInsets.only(
        left: 24,
        right: 16,
        top: 16,
        bottom: 16,
      ),
      contentPadding: const EdgeInsets.only(
        // left: 16,
        // right: 16,
        bottom: 16,
      ),
      title: Text(title),
      children: <Widget>[
        SizedBox(
          width: defaultWidgetScaling,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        )
      ],
    );
  }
}
