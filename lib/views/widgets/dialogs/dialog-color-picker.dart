import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'package:syphon/global/colours.dart';

class DialogColorPicker extends StatelessWidget {
  DialogColorPicker({
    Key? key,
    this.title = 'Color Picker',
    this.resetColor,
    this.currentColor,
    this.onCancel,
    this.onSelectColor,
  }) : super(key: key);

  final String title;
  final int? resetColor;
  final int? currentColor;
  final Function? onCancel;
  final Function? onSelectColor;

  static Widget defaultLayoutBuilder(
      BuildContext context, List<Color> colors, PickerItem child) {
    Orientation orientation = MediaQuery.of(context).orientation;

    return Container(
      width: orientation == Orientation.portrait ? 300.0 : 300.0,
      height: orientation == Orientation.portrait ? 360.0 : 200.0,
      child: GridView.count(
        crossAxisCount: orientation == Orientation.portrait ? 4 : 6,
        crossAxisSpacing: 5.0,
        mainAxisSpacing: 5.0,
        children: colors.map((Color color) => child(color)).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return SimpleDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      title: Text(title),
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
            pickerColor: Color(currentColor!),
            onColorChanged: (Color color) {
              onSelectColor!(color.value);
              Navigator.pop(context);
            },
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SimpleDialogOption(
                onPressed: () {
                  onSelectColor!(resetColor ?? null);
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
                    onPressed: () {
                      if (onCancel != null) {
                        onCancel!();
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
          ),
        )
      ],
    );
  }
}
