// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

// Package imports:

// Project imports:
import 'package:syphon/global/colours.dart';

class DialogColorPicker extends StatelessWidget {
  DialogColorPicker({
    Key key,
    this.title = 'Color Picker',
    this.resetColor,
    this.currentColor,
    this.onCancel,
    this.onSelectColor,
  }) : super(key: key);

  final String title;
  final int resetColor;
  final int currentColor;
  final Function onCancel;
  final Function onSelectColor;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return SimpleDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(title),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      children: <Widget>[
        Container(
          width: width,
          height: 248,
          child: BlockPicker(
            availableColors: const <Color>[
              MaterialColor(
                Colours.cyanSyphon,
                <int, Color>{
                  500: Color(Colours.cyanSyphon),
                },
              ),
              MaterialColor(
                Colours.chatBlue,
                <int, Color>{
                  500: Color(Colours.chatBlue),
                },
              ),
              Colors.red,
              Colors.pink,
              Colors.purple,
              Colors.deepPurple,
              Colors.indigo,
              Colors.blue,
              Colors.lightBlue,
              Colors.cyan,
              Colors.teal,
              Colors.green,
              Colors.lightGreen,
              Colors.lime,
              Colors.yellow,
              Colors.amber,
              Colors.orange,
              Colors.deepOrange,
              Colors.brown,
              Colors.grey,
              Colors.blueGrey,
              MaterialColor(
                Colours.blackFull,
                <int, Color>{
                  500: Color(Colours.blackFull),
                },
              ),
            ],
            pickerColor: Color(currentColor),
            onColorChanged: (Color color) {
              onSelectColor(color.value);
              Navigator.pop(context);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SimpleDialogOption(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
              ),
              onPressed: () {
                onSelectColor(resetColor ?? null);
                Navigator.pop(context);
              },
              child: Text(
                'reset',
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SimpleDialogOption(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  onPressed: () {
                    if (onCancel != null) {
                      onCancel();
                    }
                    Navigator.pop(context);
                  },
                  child: Text(
                    'cancel',
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ),
              ],
            )
          ],
        )
      ],
    );
  }
}
