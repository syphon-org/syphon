import 'package:flutter/scheduler.dart';
import 'package:syphon/global/libs/matrix/auth.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/views/widgets/buttons/button-solid.dart';
import 'package:syphon/views/widgets/buttons/button-text.dart';
import 'package:syphon/views/widgets/captcha.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Store
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:syphon/store/index.dart';

// Styling
import 'package:syphon/global/assets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/views/widgets/dialogs/dialog-captcha.dart';

class CaptchaStep extends StatefulWidget {
  const CaptchaStep({Key key}) : super(key: key);

  CaptchaStepState createState() => CaptchaStepState();
}

class CaptchaStepState extends State<CaptchaStep> {
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStateToProps(store),
      builder: (context, props) {
        double width = MediaQuery.of(context).size.width;

        return Container(
          child: Flex(
            direction: Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Flexible(
                flex: 6,
                child: Container(
                  width: width * 0.75,
                  constraints: BoxConstraints(
                    maxHeight: Dimensions.mediaSizeMax,
                    maxWidth: Dimensions.mediaSizeMax,
                  ),
                  child: SvgPicture.asset(
                    Assets.heroAcceptTerms,
                    semanticsLabel:
                        'Hand holding phone with checked terms of service input',
                  ),
                ),
              ),
              Flexible(
                flex: 2,
                child: Flex(
                  direction: Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(bottom: 8, top: 8),
                      child: Text(
                        'This homeserver requires a captcha\n before you can create an account.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.caption,
                      ),
                    ),
                    Container(
                      child: Stack(
                        overflow: Overflow.visible,
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 24,
                            ),
                            child: Text(
                              'Confirm you\'re alive',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headline5,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                debugPrint(
                                  'TODO: navigate to captcha explination',
                                );
                              },
                              child: Container(
                                height: 20,
                                width: 20,
                                child: Icon(
                                  Icons.info_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                flex: 1,
                child: Flex(
                  direction: Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ButtonText(
                      text: props.completed ? 'Confirmed' : 'Lood Captcha',
                      color: props.completed ? Color(0xff49c489) : null,
                      loading: props.loading,
                      disabled: props.completed,
                      onPressed: () => props.onShowCaptcha(
                        context,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      });
}

class _Props extends Equatable {
  final bool loading;
  final bool completed;

  final Function onShowCaptcha;

  _Props({
    @required this.loading,
    @required this.completed,
    @required this.onShowCaptcha,
  });

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        loading: store.state.authStore.loading,
        completed: store.state.authStore.captcha,
        onShowCaptcha: (
          BuildContext context,
        ) async {
          final authSession = store.state.authStore.session;
          await showDialog(
            context: context,
            builder: (context) {
              return DialogCaptcha(
                key: Key(authSession),
                onConfirm: () {},
              );
            },
          );
        },
      );

  @override
  List<Object> get props => [
        completed,
      ];
}
