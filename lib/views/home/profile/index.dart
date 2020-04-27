import 'package:Tether/store/user/model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'package:Tether/store/index.dart';
import 'package:Tether/store/user/selectors.dart';

import 'package:Tether/global/dimensions.dart';
import 'package:touchable_opacity/touchable_opacity.dart';
import 'package:Tether/global/behaviors.dart';

class Profile extends StatelessWidget {
  Profile({Key key}) : super(key: key);

  final String title = 'Set up Your Profile';

  Function onChangeDisplayName(Store<AppState> store) {
    return () {
      print("On Change Display Name Stub");
    };
  }

  Function onChangeAvatar(Store<AppState> store) {
    return () {
      print("On Change Avatar Stub");
    };
  }

  Function onSaveUser(Store<AppState> store) {
    return () {
      print("On Change Avatar Stub");
    };
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    return StoreConnector<AppState, Props>(
        distinct: true,
        converter: (Store<AppState> store) => Props.mapStoreToProps(store),
        builder: (context, props) {
          // Space for confirming re
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
              title: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w100,
                ),
              ),
            ),
            body: ScrollConfiguration(
              behavior: DefaultScrollBehavior(),
              child: SingleChildScrollView(
                // eventually expand as profile grows
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.075),
                  constraints: BoxConstraints(
                    maxHeight: height * 0.9,
                    maxWidth: width,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Flexible(
                        flex: 1,
                        fit: FlexFit.tight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: width * 0.24,
                              height: width * 0.24,
                              margin: const EdgeInsets.all(16.0),
                              child: TouchableOpacity(
                                activeOpacity: 0.2,
                                onTap: props.onChangeAvatar,
                                child: CircleAvatar(
                                  backgroundColor: Colors.grey,
                                  child: Text(
                                    displayInitials(props.user),
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 32.0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                          flex: 2,
                          fit: FlexFit.loose,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Container(
                                    margin: const EdgeInsets.all(8.0),
                                    constraints: BoxConstraints(
                                      maxHeight: Dimensions.inputHeight,
                                      maxWidth: Dimensions.inputWidthMax,
                                    ),
                                    child: TextField(
                                      onChanged: (name) {
                                        print('On Change Display Name Stub');
                                      },
                                      controller:
                                          TextEditingController.fromValue(
                                        TextEditingValue(
                                          text: displayName(props.user),
                                          selection: TextSelection(
                                            baseOffset:
                                                props.user.homeserver.length,
                                            extentOffset:
                                                props.user.homeserver.length,
                                          ),
                                        ),
                                      ),
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        labelText: 'Display Name',
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.all(8.0),
                                    constraints: BoxConstraints(
                                      maxHeight: Dimensions.inputHeight,
                                      maxWidth: Dimensions.inputWidthMax,
                                    ),
                                    child: TextField(
                                      onChanged: (name) {
                                        print('On Change User Id Stub');
                                      },
                                      controller:
                                          TextEditingController.fromValue(
                                        TextEditingValue(
                                          text: props.user.userId,
                                          selection: TextSelection(
                                            baseOffset:
                                                props.user.userId.length,
                                            extentOffset:
                                                props.user.userId.length,
                                          ),
                                        ),
                                      ),
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        labelText: 'User ID',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.only(bottom: 24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Container(
                                      height: Dimensions.inputHeight,
                                      margin: const EdgeInsets.all(10.0),
                                      constraints: BoxConstraints(
                                        minWidth: 200,
                                        maxWidth: 400,
                                        minHeight: 45,
                                        maxHeight: 65,
                                      ),
                                      child: FlatButton(
                                        onPressed: props.onSaveProfile,
                                        color: Theme.of(context).primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30.0,
                                          ),
                                        ),
                                        child: Text(
                                          'save',
                                          style: TextStyle(
                                              fontSize: 20,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: Dimensions.inputHeight,
                                      margin: const EdgeInsets.all(10.0),
                                      constraints: BoxConstraints(
                                          minWidth: 200, minHeight: 45),
                                      child: Visibility(
                                        child: TouchableOpacity(
                                          activeOpacity: 0.4,
                                          onTap: () => Navigator.pop(context),
                                          child: Text(
                                            'Quit editing',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w100,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }
}

class Props extends Equatable {
  final User user;
  final Function onSaveProfile;
  final Function onChangeAvatar;
  final Function onUpdateDisplayName;

  Props({
    @required this.user,
    @required this.onSaveProfile,
    @required this.onChangeAvatar,
    @required this.onUpdateDisplayName,
  });

  @override
  List<Object> get props => [
        user,
      ];

  static Props mapStoreToProps(Store<AppState> store) => Props(
        user: store.state.userStore.user,
        onSaveProfile: () {},
        onChangeAvatar: () {},
        onUpdateDisplayName: () {},
      );
}
