import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/views/behaviors.dart';
import 'package:syphon/views/widgets/buttons/button-solid.dart';

import 'password-update-step.dart';

class PasswordUpdateScreen extends StatefulWidget {
  const PasswordUpdateScreen({Key? key}) : super(key: key);

  @override
  PasswordUpdateState createState() => PasswordUpdateState();
}

class PasswordUpdateState extends State<PasswordUpdateScreen> {
  int currentStep = 0;
  bool naving = false;
  bool validStep = false;
  bool onboarding = false;
  PageController? pageController;

  var sections = [PasswordUpdateStep()];

  PasswordUpdateState();

  @override
  void initState() {
    super.initState();
    pageController = PageController(
      initialPage: 0,
      keepPage: false,
      viewportFraction: 1.5,
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          final double width = MediaQuery.of(context).size.width;
          final double height = MediaQuery.of(context).size.height;

          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
            ),
            extendBodyBehindAppBar: true,
            body: ScrollConfiguration(
              behavior: DefaultScrollBehavior(),
              child: SingleChildScrollView(
                child: Container(
                  width: width, // set actual height and width for flex constraints
                  height: height, // set actual height and width for flex constraints
                  child: Flex(
                    direction: Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Flexible(
                        flex: 9,
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
                                maxHeight: Dimensions.heightMax * 0.5,
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
                                    onboarding = index != 0 && index != sections.length - 1;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        flex: 2,
                        child: Flex(
                          mainAxisAlignment: MainAxisAlignment.center,
                          direction: Axis.vertical,
                          children: <Widget>[
                            Container(
                              width: width * 0.66,
                              height: Dimensions.inputHeight,
                              constraints: BoxConstraints(
                                minWidth: Dimensions.buttonWidthMin,
                                maxWidth: Dimensions.buttonWidthMax,
                              ),
                              child: ButtonSolid(
                                text: Strings.buttonSave,
                                loading: props.loading,
                                disabled: !props.isPasswordValid || props.loading,
                                onPressed: () async {
                                  final result = await props.onSavePassword();
                                  if (result) {
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                            ),
                          ],
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
  final Function onSavePassword;

  const _Props({
    required this.loading,
    required this.isPasswordValid,
    required this.interactiveAuths,
    required this.onSavePassword,
  });

  @override
  List<Object> get props => [
        loading,
        isPasswordValid,
        interactiveAuths,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        loading: store.state.authStore.loading,
        isPasswordValid: store.state.authStore.isPasswordValid &&
            store.state.authStore.passwordCurrent.isNotEmpty,
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
}
