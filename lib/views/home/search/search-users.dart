// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

// Project imports:
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/formatters.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/themes.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/search/actions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/home/chat/index.dart';
import 'package:syphon/views/widgets/avatars/avatar-circle.dart';
import 'package:syphon/views/widgets/dialogs/dialog-start-chat.dart';

class SearchScrollBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}

class SearchUserView extends StatefulWidget {
  const SearchUserView({Key key}) : super(key: key);

  @override
  SearchUserState createState() => SearchUserState();
}

class SearchUserState extends State<SearchUserView> {
  final searchInputFocusNode = FocusNode();

  SearchUserState({Key key});

  Timer searchTimeout;
  bool searching = false;
  String searchable;
  String creatingRoomDisplayName;

  // componentDidMount(){}
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onMounted();
  }

  @protected
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);

    if (!this.searching) {
      this.onToggleSearch(context: context);
    }

    final searchResults = store.state.searchStore.searchResults;

    // Clear search if previous results are not from User searching
    if (searchResults.isNotEmpty && !(searchResults[0] is User)) {
      store.dispatch(clearSearchResults());
    }

    searchInputFocusNode.addListener(() {
      if (!searchInputFocusNode.hasFocus) {
        searching = false;
      }
    });
  }

  @override
  void dispose() {
    searchInputFocusNode.dispose();
    super.dispose();
  }

  @protected
  void onToggleSearch({BuildContext context}) {
    setState(() {
      searching = !searching;
    });
    if (searching) {
      Timer(
        Duration(milliseconds: 1), // hack to focus after visibility change
        () => FocusScope.of(
          context,
        ).requestFocus(
          searchInputFocusNode,
        ),
      );
    } else {
      FocusScope.of(
        context,
      ).unfocus();
    }
  }

  @protected
  void onSelectUser({BuildContext context, _Props props, User user}) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) => DialogStartChat(
        user: user,
        title: 'Chat with ${user.displayName}',
        content: Strings.confirmationStartChat,
        onStartChat: () async {
          this.setState(() {
            creatingRoomDisplayName = user.displayName;
          });
          final newRoomId = await props.onCreateChatDirect(user: user);
          Navigator.pop(context);
          Navigator.popAndPushNamed(
            context,
            '/home/chat',
            arguments: ChatViewArguements(
              roomId: newRoomId,
              title: user.displayName,
            ),
          );
        },
      ),
    );
  }

  /**
   * 
   * Attempt User Chat
   * 
   * attempt chating with a user 
   * by the name searched
   */
  @protected
  void onAttemptChat({BuildContext context, _Props props, User user}) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) => DialogStartChat(
        user: user,
        title: 'Try chatting with ${user.displayName}',
        content: Strings.confirmationAttemptChat,
        onStartChat: () async {
          this.setState(() {
            creatingRoomDisplayName = user.displayName;
          });
          final newRoomId = await props.onCreateChatDirect(user: user);
          Navigator.pop(context);
          Navigator.popAndPushNamed(
            context,
            '/home/chat',
            arguments: ChatViewArguements(
              roomId: newRoomId,
              title: user.displayName,
            ),
          );
        },
      ),
    );
  }

  @protected
  Widget buildUserList(BuildContext context, _Props props) {
    final sectionBackgroundColor =
        Theme.of(context).brightness == Brightness.dark
            ? const Color(Colours.blackDefault)
            : const Color(Colours.whiteDefault);

    final searchText = searchable ?? '';

    final attemptableUser = User(
      displayName: searchText,
      userId: searchable != null && searchable.contains(":")
          ? searchable
          : formatUserId(searchText),
    );

    final foundResult = props.searchResults.indexWhere(
      (result) => result.userId.contains(searchText),
    );

    final showManualUser =
        searchable != null && searchable.length > 0 && foundResult < 0;

    return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 2,
          vertical: 4,
        ),
        child: ListView(
          children: [
            Visibility(
              visible: showManualUser,
              child: GestureDetector(
                onTap: () => this.onAttemptChat(
                  props: props,
                  context: context,
                  user: attemptableUser,
                ),
                child: Card(
                  color: sectionBackgroundColor,
                  elevation: 0,
                  child: Container(
                    padding: const EdgeInsets.only(
                      bottom: 8,
                    ),
                    child: ListTile(
                      enabled: creatingRoomDisplayName != searchable,
                      leading: AvatarCircle(
                        uri: attemptableUser.avatarUri,
                        alt: attemptableUser.displayName ??
                            attemptableUser.userId,
                      ),
                      title: Text(
                        formatDisplayName(attemptableUser),
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                      subtitle: Text(
                        attemptableUser.userId,
                        style: Theme.of(context).textTheme.caption.merge(
                              TextStyle(
                                color: props.loading
                                    ? Color(Colours.greyDisabled)
                                    : null,
                              ),
                            ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: Dimensions.progressIndicatorSize,
                            height: Dimensions.progressIndicatorSize,
                            margin: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.send,
                              size: Dimensions.iconSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              itemCount: props.searchResults.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                final user = (props.searchResults[index] as User);
                final sectionBackgroundColor =
                    Theme.of(context).brightness == Brightness.dark
                        ? const Color(Colours.blackDefault)
                        : const Color(Colours.whiteDefault);

                return GestureDetector(
                  onTap: () => this.onSelectUser(
                    context: context,
                    props: props,
                    user: user,
                  ),
                  child: Card(
                    color: sectionBackgroundColor,
                    elevation: 0,
                    child: Container(
                      padding: const EdgeInsets.only(
                        bottom: 8,
                      ),
                      child: ListTile(
                        enabled: creatingRoomDisplayName != user.displayName,
                        leading: AvatarCircle(
                          uri: user.avatarUri,
                          alt: user.displayName ?? user.userId,
                        ),
                        title: Text(
                          formatDisplayName(user),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        subtitle: Text(
                          user.userId,
                          style: Theme.of(context).textTheme.caption.merge(
                                TextStyle(
                                  color: props.loading
                                      ? Color(Colours.greyDisabled)
                                      : null,
                                ),
                              ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: Dimensions.progressIndicatorSize,
                              height: Dimensions.progressIndicatorSize,
                              margin: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(
                                Icons.send,
                                size: Dimensions.iconSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            )
          ],
        ));
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          final height = MediaQuery.of(context).size.height;

          return Scaffold(
            appBar: AppBar(
              brightness: Brightness.dark,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
              title: Stack(
                children: [
                  Visibility(
                    visible: !searching,
                    child: TouchableOpacity(
                      activeOpacity: 0.4,
                      onTap: () => onToggleSearch(context: context),
                      child: Text(
                        Strings.titleSearchUsers,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w100,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    child: Visibility(
                      visible: searching,
                      maintainState: true,
                      child: TextField(
                        focusNode: searchInputFocusNode,
                        onChanged: (text) {
                          if (this.searchTimeout != null) {
                            this.searchTimeout.cancel();
                            this.searchTimeout = null;
                          }
                          this.setState(() {
                            searchable = text;
                            searchTimeout =
                                Timer(Duration(milliseconds: 400), () {
                              props.onSearch(text);
                            });
                          });
                        },
                        cursorColor: Colors.white,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w100,
                        ),
                        decoration: InputDecoration(
                          disabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              width: 0.0,
                              color: Colors.transparent,
                            ),
                          ),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              width: 0.0,
                              color: Colors.transparent,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              width: 0.0,
                              color: Colors.transparent,
                            ),
                          ),
                          hintText: 'Search for a user...',
                          hintStyle: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w100,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                IconButton(
                  color: Colors.white,
                  icon: Icon(searching ? Icons.cancel : Icons.search),
                  onPressed: () => onToggleSearch(context: context),
                  tooltip: 'Search users',
                ),
              ],
            ),
            body: Center(
              child: Stack(
                children: [
                  buildUserList(context, props),
                  Positioned(
                    child: Visibility(
                      visible: props.loading,
                      child: Container(
                          margin: EdgeInsets.only(top: height * 0.02),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              RefreshProgressIndicator(
                                strokeWidth: Dimensions.defaultStrokeWidth,
                                valueColor: new AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                                value: null,
                              ),
                            ],
                          )),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _Props extends Equatable {
  final bool loading;
  final ThemeType theme;
  final bool creatingRoom;
  final List<dynamic> searchResults;

  final Function onSearch;
  final Function onCreateChatDirect;

  _Props({
    @required this.theme,
    @required this.loading,
    @required this.creatingRoom,
    @required this.searchResults,
    @required this.onSearch,
    @required this.onCreateChatDirect,
  });

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        theme: store.state.settingsStore.theme,
        loading: store.state.searchStore.loading,
        creatingRoom: store.state.roomStore.loading,
        searchResults: store.state.searchStore.searchResults ?? [],
        onSearch: (text) {
          store.dispatch(searchUsers(searchText: text));
        },
        onCreateChatDirect: ({User user}) async {
          return store.dispatch(createRoom(
            isDirect: true,
            invites: <User>[user],
          ));
        },
      );

  @override
  List<Object> get props => [
        loading,
        theme,
        creatingRoom,
        searchResults,
      ];
}
