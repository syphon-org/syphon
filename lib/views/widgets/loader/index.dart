// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Project imports:
import 'package:syphon/global/dimensions.dart';

class Loader extends StatelessWidget {
  Loader({
    Key? key,
    this.loading = false,
  }) : super(key: key);

  final bool loading;

  @override
  Widget build(BuildContext context) => Visibility(
        visible: this.loading,
        child: Container(
          margin: EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RefreshProgressIndicator(
                strokeWidth: Dimensions.defaultStrokeWidth,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
                value: null,
              ),
            ],
          ),
        ),
      );
}
