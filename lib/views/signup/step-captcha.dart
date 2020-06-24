import 'package:syphon/global/libs/matrix/auth.dart';
import 'package:syphon/store/auth/actions.dart';
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
                flex: 4,
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
              Container(
                width: width * 0.8,
                constraints: BoxConstraints(
                  minWidth: Dimensions.inputWidthMin,
                  maxWidth: Dimensions.inputWidthMax,
                  minHeight: 94,
                  maxHeight: 220,
                ),
                child: Captcha(
                  // TODO: confirm user wants to load captcha
                  publicKey: props.publicKey,
                  onVerified: (token) => props.onCompleteCaptcha(token),
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
        onCompleteCaptcha: (String token) {
          print('[onCompleteCaptcha] $token');
          store.dispatch(updateCredential(
            type: MatrixAuthTypes.RECAPTCHA,
            value: token.toString(),
          ));
          store.dispatch(toggleCaptcha(completed: true));
        },
      );

  @override
  List<Object> get props => [
        completed,
        publicKey,
      ];
}
