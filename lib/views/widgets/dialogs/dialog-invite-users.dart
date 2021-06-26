import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';
import 'package:redux/redux.dart';

import 'package:syphon/global/libs/matrix/auth.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/widgets/buttons/button-text.dart';

class DialogInviteUsers extends StatelessWidget {
  const DialogInviteUsers({
    Key? key,
    this.users,
    this.title = 'Invite Users',
    this.content = Strings.confirmationAttemptChat,
    this.action = 'invite users',
    this.onCancel,
    this.onInviteUsers,
  }) : super(key: key);

  final String title;
  final String content;
  final String action;
  final List<User?>? users;
  final Function? onCancel;
  final Function? onInviteUsers;

  @override
  Widget build(BuildContext context) {
    bool creating = false;

    return StatefulBuilder(
      builder: (context, setState) {
        double width = MediaQuery.of(context).size.width;

        return SimpleDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(title),
          contentPadding: EdgeInsets.symmetric(
            horizontal: width * 0.05,
            vertical: 12,
          ),
          children: <Widget>[
            Text(content),
            Container(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ButtonText(
                    textWidget: Text(
                      Strings.buttonCancel,
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    disabled: creating,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  ButtonText(
                    textWidget: Text(
                      action,
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    loading: creating,
                    disabled: creating,
                    onPressed: () async {
                      setState(() {
                        creating = true;
                      });
                      if (onInviteUsers != null) {
                        await onInviteUsers!();
                      }
                    },
                  ),
                ],
              ),
            )
          ],
        );
      },
    );
  }
}

class Props extends Equatable {
  final bool completed;
  final String? publicKey;

  final Function onCompleteCaptcha;

  Props({
    required this.completed,
    required this.publicKey,
    required this.onCompleteCaptcha,
  });

  static Props mapStateToProps(Store<AppState> store) => Props(
        completed: store.state.authStore.captcha,
        publicKey: () {
          return store.state.authStore.interactiveAuths['params'][MatrixAuthTypes.RECAPTCHA]['public_key'];
        }(),
        onCompleteCaptcha: (String token, {required BuildContext context}) async {
          await store.dispatch(updateCredential(
            type: MatrixAuthTypes.RECAPTCHA,
            value: token.toString(),
          ));
          await store.dispatch(toggleCaptcha(completed: true));
          Navigator.of(context).pop();
        },
      );

  @override
  List<Object?> get props => [
        completed,
        publicKey,
      ];
}
