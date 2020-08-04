// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Project imports:
import 'package:syphon/global/dimensions.dart';

class ButtonSolid extends StatelessWidget {
  ButtonSolid({
    Key key,
    this.text,
    this.textWidget,
    this.loading = false,
    this.disabled = false,
    this.onPressed,
  }) : super(key: key);

  final bool loading;
  final bool disabled;
  final String text;
  final Widget textWidget;
  final Function onPressed;

  @override
  Widget build(BuildContext context) => Container(
        width: Dimensions.contentWidth(context),
        height: Dimensions.inputHeight,
        constraints: BoxConstraints(
          minWidth: Dimensions.buttonWidthMin,
          maxWidth: Dimensions.buttonWidthMax,
        ),
        child: FlatButton(
          disabledColor: Colors.grey,
          disabledTextColor: Colors.grey[300],
          onPressed: disabled ? null : this.onPressed,
          color: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28.0),
          ),
          child: this.loading
              ? Container(
                  constraints: BoxConstraints(
                    maxHeight: 28,
                    maxWidth: 28,
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
                        color: Colors.white,
                      ),
                    )),
        ),
      );
}
