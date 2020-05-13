import 'package:Tether/global/colors.dart';
import 'package:Tether/store/auth/actions.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// Store
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Tether/store/index.dart';
import 'package:Tether/store/user/selectors.dart';

// Styling
import 'package:Tether/global/assets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:Tether/global/dimensions.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsStep extends StatelessWidget {
  TermsStep({Key key}) : super(key: key);
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
                  child: Stack(
                    children: [
                      SvgPicture.asset(
                        AssetsStore.heroSyncFiles,
                        semanticsLabel:
                            'Hand holding phone with checked terms of service input',
                      ),
                      Positioned(
                        bottom: 2,
                        right: 38,
                        child: Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            color: const Color(TETHERED_CYAN),
                          ),
                          child: Container(
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      )
                    ],
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
                        '${props.homeserver} requires you read\nand agree to a terms of service.',
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
                              'Agree to Terms of Service',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headline5,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                print(
                                  'TODO: navigate to terms of service explination',
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
              Container(
                width: width * 0.8,
                constraints: BoxConstraints(
                  minWidth: Dimensions.inputWidthMin,
                  maxWidth: Dimensions.inputWidthMax,
                  minHeight: 94,
                  maxHeight: 160,
                ),
                child: GestureDetector(
                  onTap: () {
                    props.onToggleAgreement();
                    if (!props.agreement) {
                      props.onViewTermsOfService();
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(right: 6),
                        child: Icon(
                          props.agreement
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                        ),
                      ),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: 'Agree to ${props.homeserver} ',
                          style: Theme.of(context).textTheme.subtitle1,
                          children: <TextSpan>[
                            TextSpan(
                              text: 'terms of service',
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1
                                  .copyWith(
                                    fontWeight: FontWeight.w400,
                                    decorationStyle: TextDecorationStyle.solid,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      });
}

class _Props extends Equatable {
  final bool agreement;
  final String homeserver;

  final Function onToggleAgreement;
  final Function onViewTermsOfService;

  _Props({
    @required this.homeserver,
    @required this.agreement,
    @required this.onToggleAgreement,
    @required this.onViewTermsOfService,
  });

  static _Props mapStoreToProps(Store<AppState> store) => _Props(
      homeserver:
          store.state.authStore.homeserver.substring(0, 1).toUpperCase() +
              store.state.authStore.homeserver.substring(1),
      agreement: store.state.authStore.agreement,
      onToggleAgreement: () {
        store.dispatch(toggleAgreement());
      },
      onViewTermsOfService: () async {
        final termsOfServiceUrl = store.state.authStore.credential.termsUrl;
        if (await canLaunch(termsOfServiceUrl)) {
          await launch(termsOfServiceUrl);
        } else {
          throw 'Could not launch $termsOfServiceUrl';
        }
      });

  @override
  List<Object> get props => [
        agreement,
        homeserver,
      ];
}
