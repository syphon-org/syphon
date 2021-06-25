import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/libs/matrix/auth.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/views/widgets/buttons/button-text.dart';
import 'package:syphon/views/widgets/captcha.dart';

class DialogCaptcha extends StatelessWidget {
  const DialogCaptcha({
    Key? key,
    this.onConfirm,
    this.onCancel,
  }) : super(key: key);

  final Function? onConfirm;
  final Function? onCancel;

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
      distinct: true,
      converter: (Store<AppState> store) => Props.mapStateToProps(store),
      builder: (context, props) {
        final double width = MediaQuery.of(context).size.width;
        final double height = MediaQuery.of(context).size.height;

        return SimpleDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: EdgeInsets.only(
            left: 24,
            right: 16,
            top: 16,
            bottom: 16,
          ),
          contentPadding: EdgeInsets.only(
            left: 8,
            right: 8,
            bottom: 16,
          ),
          title: Text(
            Strings.titleDialogCaptcha,
          ),
          children: <Widget>[
            Container(
              width: width,
              child: SingleChildScrollView(
                child: Container(
                  width: width,
                  height: height * 0.5,
                  constraints: BoxConstraints(
                    minWidth: Dimensions.inputWidthMin,
                    maxWidth: Dimensions.inputWidthMax,
                  ),
                  child: Captcha(
                    publicKey: props.publicKey,
                    onVerified: (token) =>
                        props.onCompleteCaptcha(token, context: context),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                ButtonText(
                  text: 'Cancel',
                  onPressed: () {
                    if (onCancel != null) {
                      onCancel!();
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            )
          ],
        );
      });
}

class Props extends Equatable {
  final bool completed;
  final String? publicKey;

  final Function onCompleteCaptcha;

  const Props({
    required this.completed,
    required this.publicKey,
    required this.onCompleteCaptcha,
  });

  @override
  List<Object?> get props => [
        completed,
        publicKey,
      ];

  static Props mapStateToProps(Store<AppState> store) => Props(
        completed: store.state.authStore.captcha,
        publicKey: () {
          return store.state.authStore.interactiveAuths['params']
              [MatrixAuthTypes.RECAPTCHA]['public_key'];
        }(),
        onCompleteCaptcha: (String token,
            {required BuildContext context}) async {
          await store.dispatch(updateCredential(
            type: MatrixAuthTypes.RECAPTCHA,
            value: token.toString(),
          ));
          await store.dispatch(toggleCaptcha(completed: true));
          Navigator.of(context).pop();
        },
      );
}
