import 'dart:async';

import 'package:syphon/global/strings.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:syphon/store/index.dart';

// Styling Widgets
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/behaviors.dart';

import './step-password.dart';

final Duration nextAnimationDuration = Duration(milliseconds: 350);

class PasswordView extends StatefulWidget {
  const PasswordView({Key key}) : super(key: key);

  PasswordUpdateState createState() => PasswordUpdateState();
}

class PasswordUpdateState extends State<PasswordView> {
  final String title = Strings.titleViewSignup;

  int currentStep = 0;
  bool onboarding = false;
  bool validStep = false;
  bool naving = false;
  StreamSubscription subscription;
  PageController pageController;

  var sections = [
    PasswordStep(),
  ];

  PasswordUpdateState({Key key});

  @override
  void initState() {
    super.initState();
    pageController = PageController(
      initialPage: 0,
      keepPage: false,
      viewportFraction: 1.5,
    );

    SchedulerBinding.instance.addPostFrameCallback((_) {
      onMounted();
    });
  }

  @protected
  void onMounted() async {
    final store = StoreProvider.of<AppState>(context);

    // TODO: not sure what this was fore
    // subscription = store.onChange.listen((state) {
    //   print('[PasswordUpdate] ${state.authStore.passwordCurrent}');

    //   if (state.authStore.user.accessToken != null) {
    //   print('access token ${accessToken}');
    //   }
    // });
  }

  @override
  void deactivate() {
    subscription.cancel();
    super.deactivate();
  }

  @protected
  void onBackStep(BuildContext context) {
    Navigator.pop(context, false);
  }

  @protected
  Function onCheckStepValidity(_Props props) {
    return !props.isPasswordValid
        ? null
        : () async {
            final result = await props.onSavePassword();
            if (result) {
              Navigator.pop(context);
            }
          };
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStoreToProps(store),
        builder: (context, props) {
          double width = MediaQuery.of(context).size.width;
          double height = MediaQuery.of(context).size.height;

          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  onBackStep(context);
                },
              ),
            ),
            body: ScrollConfiguration(
              behavior: DefaultScrollBehavior(),
              child: SingleChildScrollView(
                child: Container(
                  width:
                      width, // set actual height and width for flex constraints
                  height:
                      height, // set actual height and width for flex constraints
                  child: Flex(
                    direction: Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Flexible(
                        flex: 8,
                        fit: FlexFit.tight,
                        child: Flex(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          direction: Axis.horizontal,
                          children: <Widget>[
                            Container(
                              width: width,
                              constraints: BoxConstraints(
                                minHeight: Dimensions.pageViewerHeightMin,
                                maxHeight: Dimensions.widgetHeightMax * 0.6,
                              ),
                              child: PageView(
                                pageSnapping: true,
                                allowImplicitScrolling: false,
                                controller: pageController,
                                physics: NeverScrollableScrollPhysics(),
                                children: sections,
                                onPageChanged: (index) {
                                  setState(() {
                                    currentStep = index;
                                    onboarding = index != 0 &&
                                        index != sections.length - 1;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: Flex(
                          mainAxisAlignment: MainAxisAlignment.end,
                          direction: Axis.vertical,
                          children: <Widget>[
                            Container(
                              width: width * 0.66,
                              margin: EdgeInsets.only(top: height * 0.01),
                              height: Dimensions.inputHeight,
                              constraints: BoxConstraints(
                                minWidth: Dimensions.buttonWidthMin,
                                maxWidth: Dimensions.buttonWidthMax,
                              ),
                              child: FlatButton(
                                disabledColor: Colors.grey,
                                disabledTextColor: Colors.grey[300],
                                onPressed: onCheckStepValidity(props),
                                color: Theme.of(context).primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                child: !props.loading
                                    ? Text(
                                        Strings.buttonSaveGeneric,
                                      )
                                    : CircularProgressIndicator(
                                        strokeWidth:
                                            Dimensions.defaultStrokeWidthLite,
                                        backgroundColor: Colors.white,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.grey,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 20,
                        ),
                        constraints: BoxConstraints(
                          minHeight: 45,
                        ),
                        child: Flex(
                          direction: Axis.horizontal,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class _Props extends Equatable {
  final bool loading;
  final bool isPasswordValid;
  final Map interactiveAuths;

  final Function onAddAlert;
  final Function onSavePassword;

  _Props({
    @required this.loading,
    @required this.isPasswordValid,
    @required this.interactiveAuths,
    @required this.onAddAlert,
    @required this.onSavePassword,
  });

  static _Props mapStoreToProps(Store<AppState> store) => _Props(
        loading: store.state.authStore.loading,
        isPasswordValid: store.state.authStore.isPasswordValid &&
            store.state.authStore.passwordCurrent != null &&
            store.state.authStore.passwordCurrent.length > 0,
        interactiveAuths: store.state.authStore.interactiveAuths,
        onSavePassword: () async {
          final valid = store.state.authStore.isPasswordValid;
          if (!valid) return;

          final newPassword = store.state.authStore.password;
          return await store.dispatch(
            updatePassword(newPassword),
          );
        },
      );

  @override
  List<Object> get props => [
        loading,
        isPasswordValid,
        interactiveAuths,
      ];
}
