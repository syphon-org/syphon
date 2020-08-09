// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Project imports:
import 'package:syphon/global/dimensions.dart';

class ButtonText extends StatelessWidget {
  ButtonText({
    Key key,
    this.text,
    this.textWidget,
    this.loading = false,
    this.disabled = false,
    this.color,
    this.onPressed,
  }) : super(key: key);

  final bool loading;
  final bool disabled;
  final String text;
  final Widget textWidget;
  final Color color;
  final Function onPressed;

  @override
  Widget build(BuildContext context) => FlatButton(
        disabledTextColor: Colors.grey[300],
        onPressed: disabled ? null : this.onPressed,
        child: this.loading
            ? Container(
                constraints: BoxConstraints(
                  maxHeight: 24,
                  maxWidth: 24,
                ),
                child: CircularProgressIndicator(
                  strokeWidth: Dimensions.defaultStrokeWidth,
                  backgroundColor: Colors.white,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.grey,
                  ),
                ),
              )
            : (textWidget != null
                ? textWidget
                : Text(
                    this.text,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w100,
                      letterSpacing: 0.8,
                      color: () {
                        if (disabled) {
                          return Colors.grey[300];
                        }
                        if (color != null) {
                          return color;
                        }
                        return Theme.of(context).buttonColor;
                      }(),
                    ),
                  )),
      );
}
