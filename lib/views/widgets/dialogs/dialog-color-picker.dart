import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'package:syphon/global/colors.dart';
import 'package:syphon/global/strings.dart';

class DialogColorPicker extends StatefulWidget {
  const DialogColorPicker({
    super.key,
    required this.title, // i18n Strings isn't a constant. You gotta pass it in
    required this.currentColor,
    this.advanced = false,
    this.resetColor,
    this.onCancel,
    this.onSelectColor,
    this.onToggleAdvanced,
  });

  final String title;
  final int? resetColor;
  final int currentColor;
  final bool advanced;
  final Function? onCancel;
  final Function? onToggleAdvanced;
  final Function? onSelectColor;

  @override
  _DialogColorPickerState createState() => _DialogColorPickerState();
}

class _DialogColorPickerState extends State<DialogColorPicker> {
  Color? currentColor;

  TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  buildDefaultPicker(context) => BlockPicker(
        availableColors: const <Color>[
          MaterialColor(
            AppColors.cyanSyphon,
            <int, Color>{
              500: Color(AppColors.cyanSyphon),
            },
          ),
          MaterialColor(
            AppColors.chatBlue,
            <int, Color>{
              500: Color(AppColors.chatBlue),
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
            AppColors.blackFull,
            <int, Color>{
              500: Color(AppColors.blackFull),
            },
          ),
        ],
        pickerColor: Color(widget.currentColor),
        onColorChanged: (Color color) {
          widget.onSelectColor!(color.value);
          Navigator.pop(context);
        },
      );

  buildAdvancedPicker(context) => ColorPicker(
        pickerColor: currentColor ?? Color(widget.currentColor),
        hexInputController: controller,
        labelTypes: const [],
        onColorChanged: (Color color) {
          widget.onSelectColor!(color.value);
          setState(() {
            currentColor = color;
          });
        },
      );

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;

    var dialogHeight = 200.0;

    if (orientation == Orientation.portrait) {
      dialogHeight = 360;
    }

    if (widget.advanced) {
      dialogHeight = height / 1.80;
    }

    const optionsPadding = EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0);

    final options = [
      SimpleDialogOption(
        onPressed: () {
          widget.onSelectColor!(widget.resetColor);
          Navigator.pop(context);
        },
        child: Text(
          'reset',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    ];

    if (!widget.advanced) {
      if (widget.onToggleAdvanced != null) {
        options.add(
          SimpleDialogOption(
            padding: optionsPadding,
            onPressed: () {
              Navigator.pop(context);
              widget.onToggleAdvanced!();
            },
            child: Text(
              Strings.titleAdvanced.toLowerCase(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        );
      }

      options.add(
        SimpleDialogOption(
          padding: optionsPadding,
          onPressed: () {
            widget.onCancel?.call();
            Navigator.pop(context);
          },
          child: Text(
            Strings.buttonCancel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    if (widget.advanced) {
      options.add(
        SimpleDialogOption(
          padding: optionsPadding,
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            Strings.buttonConfirmFormal,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    return SimpleDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      title: Text(widget.title),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
          ),
          width: width,
          height: dialogHeight,
          constraints: !widget.advanced ? null : const BoxConstraints(minHeight: 460),
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (widget.advanced) buildAdvancedPicker(context) else buildDefaultPicker(context),
                Visibility(
                  visible: widget.advanced,
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      labelText: 'HEX',
                    ),
                    controller: controller,
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: options,
          ),
        )
      ],
    );
  }
}
