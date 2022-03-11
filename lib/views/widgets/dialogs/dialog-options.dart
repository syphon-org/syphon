import 'package:flutter/material.dart';

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';

import 'package:syphon/views/widgets/buttons/button-text.dart';

///
/// Confirmation Dialog
///
/// Use this *instead* of AlertDialog
/// as they come with desired styling and generally
/// what is needed for a confirmation layout
///
class DialogOptions extends StatelessWidget {
  const DialogOptions({
    Key? key,
    this.title = '',
    this.content = '',
    this.loading = false,
    this.confirmText,
    this.confirmStyle,
    this.dismissStyle,
    this.dismissText,
    this.onConfirm,
    this.onDismiss,
  }) : super(key: key);

  final String title;
  final String content;

  final bool loading;
  final String? dismissText;
  final String? confirmText;

  final TextStyle? confirmStyle;
  final TextStyle? dismissStyle;

  final Function? onConfirm;
  final Function? onDismiss;

  @override
  Widget build(BuildContext context) => SimpleDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(title),
        titlePadding: Dimensions.dialogPadding,
        contentPadding: Dimensions.dialogPadding,
        children: <Widget>[
          Text(content),
          Container(
            padding: EdgeInsets.only(top: 8),
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                ButtonText(
                  disabled: loading,
                  onPressed: () => onDismiss!(),
                  textWidget: Text(
                    dismissText ?? Strings.buttonCancel.capitalize(),
                    style: Theme.of(context).textTheme.subtitle1?.merge(dismissStyle).copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                ButtonText(
                  disabled: loading,
                  onPressed: () => onConfirm!(),
                  textWidget: Text(
                    confirmText ?? Strings.buttonConfirm.capitalize(),
                    style: Theme.of(context)
                        .textTheme
                        .subtitle1
                        ?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        )
                        .merge(confirmStyle),
                  ),
                ),
              ],
            ),
          )
        ],
      );
}
