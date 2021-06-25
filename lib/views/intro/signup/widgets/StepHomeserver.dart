import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:redux/redux.dart';

import 'package:syphon/global/assets.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/libs/matrix/auth.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/auth/homeserver/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/input/text-field-secure.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

class HomeserverStep extends StatefulWidget {
  const HomeserverStep({Key? key}) : super(key: key);

  HomeserverStepState createState() => HomeserverStepState();
}

class HomeserverStepState extends State<HomeserverStep> {
  HomeserverStepState();

  final homeserverController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onMounted();
  }

  @protected
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);
    final hostname = store.state.authStore.hostname;
    final homeserver = store.state.authStore.homeserver;
    homeserverController.text = homeserver.hostname ?? hostname;
  }

  buildContinueSSO(_Props props) => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: Avatar(
            size: Dimensions.avatarSizeMin,
            url: props.homeserver.photoUrl,
            alt: props.homeserver.hostname ?? '',
            background: Colours.hashedColor(props.homeserver.hostname),
          ),
          title: Text(
            props.homeserver.hostname ?? '',
            style: Theme.of(context).textTheme.headline6,
          ),
          subtitle: Text(
            props.homeserver.baseUrl ?? '',
            style: Theme.of(context).textTheme.caption,
          ),
          trailing: TouchableOpacity(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/search/homeservers',
              );
            },
            child: Icon(
              Icons.search_rounded,
              size: Dimensions.iconSizeLarge,
            ),
          ),
        ),
      );

  buildContinueNormal(_Props props) => Container(
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
            props.onSetHostname(text);
          },
          onEditingComplete: () {
            props.onChangeHomeserver(props.hostname);
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
      );

  buildContinue(_Props props) {
    if (props.homeserver.loginType == MatrixAuthTypes.SSO) {
      return buildContinueSSO(props);
    }
    return buildContinueNormal(props);
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStateToProps(store),
      onWillChange: (oldProps, newProps) {
        if (oldProps!.homeserver.hostname != newProps.homeserver.hostname) {
          homeserverController.text = newProps.homeserver.hostname!;
        }
      },
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
                    semanticsLabel:
                        'User resting their leg on an at symbol stool box',
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
                  width: Dimensions.contentWidth(context),
                  child: buildContinue(props),
                ),
              ),
            ],
          ),
        );
      });
}

class _Props extends Equatable {
  final String hostname;
  final Homeserver homeserver;

  final Function onSetHostname;
  final Function onChangeHomeserver;

  _Props({
    required this.hostname,
    required this.homeserver,
    required this.onSetHostname,
    required this.onChangeHomeserver,
  });

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        hostname: store.state.authStore.hostname,
        homeserver: store.state.authStore.homeserver,
        onSetHostname: (String hostname) {
          store.dispatch(setHostname(hostname: hostname));
        },
        onChangeHomeserver: (String hostname) {
          store.dispatch(selectHomeserver(hostname: hostname));
        },
      );

  @override
  List<Object> get props => [
        homeserver,
      ];
}
