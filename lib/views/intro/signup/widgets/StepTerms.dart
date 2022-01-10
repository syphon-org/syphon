import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:redux/redux.dart';

import 'package:syphon/global/assets.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/libs/matrix/auth.dart';
import 'package:syphon/global/weburl.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/index.dart';

class TermsStep extends StatelessWidget {
  TermsStep({Key? key}) : super(key: key);
  final focusNode = FocusNode();

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStateToProps(store),
      builder: (context, props) {
        final double width = MediaQuery.of(context).size.width;
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
                    maxHeight: Dimensions.mediaSize,
                    maxWidth: Dimensions.mediaSize,
                  ),
                  padding: EdgeInsets.only(
                    bottom: 24,
                  ),
                  child: Stack(
                    children: [
                      SvgPicture.asset(
                        Assets.heroSyncFiles,
                        semanticsLabel: 'A couple of documents with a checked circle on the bottom',
                      ),
                      Positioned(
                        bottom: 0,
                        right: 24,
                        child: Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            color: const Color(Colours.cyanSyphon),
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
                        clipBehavior: Clip.none,
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
                                // TODO: show terms of service explaination dialog
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.only(
                              top: 8,
                              left: 8,
                              right: 8,
                              bottom: 8,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                props.onToggleAgreement();
                              },
                              child: Icon(
                                props.agreement ? Icons.check_box : Icons.check_box_outline_blank,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              props.onViewTermsOfService();
                            },
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                text: 'Agree to ${props.homeserver} ',
                                style: Theme.of(context).textTheme.subtitle1,
                                children: <TextSpan>[
                                  TextSpan(
                                    text: 'terms of service',
                                    style: Theme.of(context).textTheme.subtitle1!.copyWith(
                                          fontWeight: FontWeight.w400,
                                          decorationStyle: TextDecorationStyle.solid,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
  final bool agreement;
  final String homeserver;

  final Function onToggleAgreement;
  final Function onViewTermsOfService;

  const _Props({
    required this.homeserver,
    required this.agreement,
    required this.onToggleAgreement,
    required this.onViewTermsOfService,
  });

  static _Props mapStateToProps(Store<AppState> store) => _Props(
      homeserver: store.state.authStore.hostname.substring(0, 1).toUpperCase() +
          store.state.authStore.hostname.substring(1),
      agreement: store.state.authStore.agreement,
      onToggleAgreement: () async {
        store.dispatch(toggleAgreement());

        if (store.state.authStore.agreement) {
          store.dispatch(updateCredential(
            type: MatrixAuthTypes.TERMS,
          ));
        } else {
          store.dispatch(updateCredential(
            type: MatrixAuthTypes.DUMMY,
          ));
        }
      },
      onViewTermsOfService: () async {
        try {
          final termsOfServiceUrl = store.state.authStore.credential!.termsUrl!;
          launchUrl(termsOfServiceUrl);
        } catch (error) {}
      });

  @override
  List<Object> get props => [
        agreement,
        homeserver,
      ];
}
