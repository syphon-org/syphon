// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:redux/redux.dart';

// Project imports:
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/widgets/input/text-field-secure.dart';

// Store

// Styling

class HomeserverStep extends StatefulWidget {
  const HomeserverStep({Key key}) : super(key: key);

  HomeserverStepState createState() => HomeserverStepState();
}

class HomeserverStepState extends State<HomeserverStep> {
  HomeserverStepState({Key key});

  final homeserverController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onMounted();
  }

  @protected
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);
    homeserverController.text = store.state.authStore.homeserver;
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStateToProps(store),
      builder: (context, props) {
        double height = MediaQuery.of(context).size.height;

        return Container(
          margin: EdgeInsets.symmetric(
            vertical: height * 0.01,
          ),
          child: Flex(
            direction: Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Flexible(
                flex: 2,
                child: Container(
                  width: Dimensions.contentWidth(context),
                  constraints: BoxConstraints(
                    maxHeight: Dimensions.mediaSizeMax,
                    maxWidth: Dimensions.mediaSizeMax,
                  ),
                  child: SvgPicture.asset(
                    Assets.heroSignupHomeserver,
                    semanticsLabel: 'User hidding behind a message',
                  ),
                ),
              ),
              Flexible(
                flex: 1,
                child: Flex(
                  direction: Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Find a homeserver',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headline5,
                    ),
                  ],
                ),
              ),
              Flexible(
                flex: 1,
                child: Container(
                  width: Dimensions.contentWidthWide(context),
                  height: Dimensions.inputHeight,
                  constraints: BoxConstraints(
                    minWidth: Dimensions.inputWidthMin,
                    maxWidth: Dimensions.inputWidthMax,
                  ),
                  child: TextFieldSecure(
                    label: 'Homeserver',
                    disableSpacing: true,
                    controller: homeserverController,
                    onChanged: (text) {
                      props.onChangeHomeserver(text);
                    },
                    onEditingComplete: () {
                      props.onChangeHomeserver(props.homeserver);
                      FocusScope.of(context).unfocus();
                    },
                    suffix: IconButton(
                        icon: Icon(Icons.search),
                        tooltip: 'Find your homeserver',
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/search/homeservers',
                          );
                        }),
                  ),
                ),
              ),
            ],
          ),
        );
      });
}

class _Props extends Equatable {
  final String homeserver;

  final Function onChangeHomeserver;

  _Props({
    @required this.homeserver,
    @required this.onChangeHomeserver,
  });

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        homeserver: store.state.authStore.homeserver,
        onChangeHomeserver: (String text) {
          store.dispatch(setHomeserver(homeserver: text.trim()));
        },
      );

  @override
  List<Object> get props => [
        homeserver,
      ];
}
