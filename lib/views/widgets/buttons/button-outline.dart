// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Project imports:
import 'package:syphon/global/dimensions.dart';

class ButtonOutline extends StatelessWidget {
  ButtonOutline({
    Key key,
    this.text,
    this.loading = false,
    this.disabled = false,
    this.width,
    this.height,
    this.child,
    this.onPressed,
  }) : super(key: key);

  final bool loading;
  final bool disabled;
  final double width;
  final double height;
  final String text;
  final Widget child;
  final Function onPressed;

  @override
  Widget build(BuildContext context) => Container(
        width: width ?? Dimensions.contentWidth(context),
        height: height ?? Dimensions.inputHeight,
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
              : (child != null
                  ? child
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
