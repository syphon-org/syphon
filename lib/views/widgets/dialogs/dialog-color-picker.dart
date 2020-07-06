import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    double height = MediaQuery.of(context).size.height;

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
          child: MaterialColorPicker(
            onlyShadeSelection: true,
            selectedColor: Color(currentColor),
            onColorChange: (Color color) {
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
