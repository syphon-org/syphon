import 'package:Tether/global/libs/matrix/auth.dart';
import 'package:Tether/store/auth/actions.dart';
import 'package:Tether/views/widgets/captcha.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Store
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Tether/store/index.dart';

// Styling
import 'package:Tether/global/assets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:Tether/global/dimensions.dart';

class CaptchaStep extends StatelessWidget {
  CaptchaStep({Key key}) : super(key: key);
  final focusNode = FocusNode();

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStoreToProps(store),
      builder: (context, props) {
        double width = MediaQuery.of(context).size.width;

        return Container(
          child: Flex(
            direction: Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Flexible(
                flex: 2,
                child: Container(
                  width: width * 0.75,
                  constraints: BoxConstraints(
                    maxHeight: Dimensions.mediaSizeMax,
                    maxWidth: Dimensions.mediaSizeMax,
                  ),
                  child: SvgPicture.asset(
                    AssetsStore.heroAcceptTerms,
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
                                print('TODO: navigate to captcha explination');
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
                child: Container(
                  width: width * 0.8,
                  height: Dimensions.inputHeight,
                  constraints: BoxConstraints(
                    minWidth: Dimensions.inputWidthMin,
                    maxWidth: Dimensions.inputWidthMax,
                  ),
                  child: Captcha(
                    publicKey: props.publicKey,
                  ),
                ),
              ),
            ],
          ),
        );
      });
}

class _Props extends Equatable {
  final bool completed;
  final String publicKey;

  final Function onCompleteCaptcha;

  _Props({
    @required this.completed,
    @required this.publicKey,
    @required this.onCompleteCaptcha,
  });

  static _Props mapStoreToProps(Store<AppState> store) => _Props(
        completed: store.state.authStore.captcha,
        publicKey: () {
          return store.state.authStore.interactiveAuths['params']
              [MatrixAuthTypes.RECAPTCHA]['public_key'];
        }(),
        onCompleteCaptcha: (bool completed) {
          store.dispatch(updateCredential(
            type: MatrixAuthTypes.RECAPTCHA,
            value: completed.toString(),
          ));
          store.dispatch(toggleCaptcha(
            completed: !store.state.authStore.captcha,
          ));
        },
      );

  @override
  List<Object> get props => [
        completed,
        publicKey,
      ];
}
