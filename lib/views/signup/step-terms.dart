import 'package:Tether/store/auth/actions.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
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
                flex: 1,
                child: Flex(
                  direction: Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Stack(
                      children: <Widget>[
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                        Text(
                          'Terms Of Service',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headline5,
                        ),
                      ],
                    )
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
                  child: Container(
                    width: 12,
                    height: 12,
                    margin: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Container(
                      padding: EdgeInsets.all((6)),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                      ),
                    ),
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

  final Function onToggleAgreement;

  _Props({
    @required this.agreement,
    @required this.onToggleAgreement,
  });

  static _Props mapStoreToProps(Store<AppState> store) => _Props(
        agreement: store.state.authStore.agreement,
        onToggleAgreement: (bool agreement) {
          store.dispatch(toggleAgreement(
            agreement: !store.state.authStore.agreement,
          ));
        },
      );

  @override
  List<Object> get props => [
        homeserver,
      ];
}
