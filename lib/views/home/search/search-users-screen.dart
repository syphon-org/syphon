// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/svg.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/views/widgets/appbars/appbar-search.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';
import 'package:syphon/views/widgets/loader/index.dart';
import 'package:syphon/views/widgets/modals/modal-user-details.dart';

// Project imports:
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/formatters.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/search/actions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/home/chat/chat-screen.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/dialogs/dialog-start-chat.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({Key? key}) : super(key: key);

  @override
  SearchUserState createState() => SearchUserState();
}

class SearchUserState extends State<SearchUserScreen> {
  final searchInputFocusNode = FocusNode();

  SearchUserState({Key? key});

  String? searchable;
  String? creatingRoomDisplayName;

  // componentDidMount(){}
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onMounted();
  }

  @protected
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);

    final searchResults = store.state.searchStore.searchResults;

    // Clear search if previous results are not from User searching
    if (searchResults.isNotEmpty && !(searchResults[0] is User)) {
      store.dispatch(clearSearchResults());
    }
  }

  @override
  void dispose() {
    searchInputFocusNode.dispose();
    super.dispose();
  }

  @protected
  onShowUserDetails({
    required BuildContext context,
    User? user,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalUserDetails(
        user: user,
        nested: true,
      ),
    );
  }

  @protected
  void onMessageUser(
      {required BuildContext context, _Props? props, User? user}) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) => DialogStartChat(
        user: user,
        title: 'Chat with ${formatUsername(user!)}',
        content: Strings.confirmationStartChat,
        onStartChat: () async {
          setState(() {
            creatingRoomDisplayName = user.displayName;
          });
          final newRoomId = await props!.onCreateChatDirect(user: user);

          Navigator.pop(context);

          if (newRoomId != null) {
            Navigator.popAndPushNamed(
              context,
              '/home/chat',
              arguments: ChatViewArguements(
                roomId: newRoomId,
                title: user.displayName,
              ),
            );
          }
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
  void onAttemptChat({
    required User user,
    required BuildContext context,
    _Props? props,
  }) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) => DialogStartChat(
        user: user,
        title: 'Try chatting with ${formatUsername(user)}',
        content: Strings.confirmationAttemptChat,
        onStartChat: () async {
          setState(() {
            creatingRoomDisplayName = user.displayName;
          });
          final newRoomId = await props!.onCreateChatDirect(user: user);

          Navigator.pop(context);

          if (newRoomId != null) {
            Navigator.popAndPushNamed(
              context,
              '/home/chat',
              arguments: ChatViewArguements(
                roomId: newRoomId,
                title: user.displayName,
              ),
            );
          }
        },
      ),
    );
  }

  @protected
  Widget buildUserList(BuildContext context, _Props props) {
    final searchText = searchable ?? '';

    final attemptableUser = User(
      displayName: searchText,
      userId: searchable != null && searchable!.contains(":")
          ? searchable
          : formatUserId(searchText),
    );

    final foundResult = props.searchResults.indexWhere(
      (result) => result.userId.contains(searchText),
    );

    final showManualUser =
        searchable != null && searchable!.length > 0 && foundResult < 0;

    final usersList = searchable == null || searchable!.isEmpty
        ? props.usersRecent
        : props.searchResults;

    return ListView(
      children: [
        Visibility(
          visible: searchable == null || searchable!.isEmpty,
          child: Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
            ),
            child: Row(
              children: [
                Text(
                  'Recent Users',
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.subtitle2,
                ),
              ],
            ),
          ),
        ),
        Visibility(
          visible: showManualUser,
          child: GestureDetector(
            onTap: () => onAttemptChat(
              props: props,
              context: context,
              user: attemptableUser,
            ),
            child: CardSection(
              padding: EdgeInsets.zero,
              elevation: 0,
              child: Container(
                child: ListTile(
                  enabled: creatingRoomDisplayName != searchable,
                  leading: Avatar(
                    uri: attemptableUser.avatarUri,
                    alt: attemptableUser.displayName ?? attemptableUser.userId,
                    size: Dimensions.avatarSizeMin,
                  ),
                  title: Text(
                    formatUsername(attemptableUser),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                  subtitle: Text(
                    attemptableUser.userId!,
                    style: Theme.of(context).textTheme.caption!.merge(
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
                        width: Dimensions.iconSizeLite,
                        height: Dimensions.iconSizeLite,
                        child: SvgPicture.asset(
                          Assets.iconSendBeing,
                          height: Dimensions.iconSize,
                          width: Dimensions.iconSize,
                          semanticsLabel: Strings.semanticsSendUnencrypted,
                          color: Theme.of(context).iconTheme.color,
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
          itemCount: usersList.length,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            final user = (usersList[index] as User);

            return GestureDetector(
              onTap: () => this.onShowUserDetails(
                context: context,
                user: user,
              ),
              child: CardSection(
                padding: EdgeInsets.zero,
                elevation: 0,
                child: Container(
                  child: ListTile(
                    enabled: creatingRoomDisplayName != user.displayName,
                    leading: Avatar(
                      uri: user.avatarUri,
                      alt: user.displayName ?? user.userId,
                      size: Dimensions.avatarSizeMin,
                      background: Colours.hashedColor(formatUsername(user)),
                    ),
                    title: Text(
                      formatUsername(user),
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyText1,
                    ),
                    subtitle: Text(
                      user.userId!,
                      style: Theme.of(context).textTheme.caption!.merge(
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
                        GestureDetector(
                          onTap: () => this.onMessageUser(
                            context: context,
                            props: props,
                            user: user,
                          ),
                          child: Container(
                            width: Dimensions.iconSizeLite,
                            height: Dimensions.iconSizeLite,
                            child: SvgPicture.asset(
                              Assets.iconSendBeing,
                              fit: BoxFit.contain,
                              height: Dimensions.iconSize,
                              width: Dimensions.iconSize,
                              color: Theme.of(context).iconTheme.color,
                              semanticsLabel: Strings.semanticsSendUnencrypted,
                            ),
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
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          return Scaffold(
            appBar: AppBarSearch(
              title: Strings.titleSearchUsers,
              label: 'Search for a user...',
              tooltip: 'Search users',
              brightness: Brightness.dark,
              forceFocus: true,
              focusNode: searchInputFocusNode,
              onChange: (text) => setState(() {
                searchable = text;
              }),
              onSearch: (text) {
                setState(() {
                  searchable = text;
                });
                props.onSearch(text);
              },
            ),
            body: Stack(
              children: [
                buildUserList(context, props),
                Positioned(
                  child: Loader(
                    loading: props.loading,
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _Props extends Equatable {
  final bool loading;
  final ThemeType themeType;
  final bool creatingRoom;
  final List<User> usersRecent;
  final List<dynamic> searchResults;

  final Function onSearch;
  final Function onCreateChatDirect;

  _Props({
    required this.themeType,
    required this.loading,
    required this.creatingRoom,
    required this.searchResults,
    required this.usersRecent,
    required this.onSearch,
    required this.onCreateChatDirect,
  });

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        themeType: store.state.settingsStore.appTheme.themeType,
        loading: store.state.searchStore.loading,
        creatingRoom: store.state.roomStore.loading,
        usersRecent: friendlyUsers(store.state),
        searchResults: store.state.searchStore.searchResults,
        onSearch: (String text) {
          if (text.contains('@') && text.length == 1) {
            return;
          }

          store.dispatch(searchUsers(searchText: text));
        },
        onCreateChatDirect: ({required User user}) async {
          return store.dispatch(createRoom(
            isDirect: true,
            invites: <User>[user],
          ));
        },
      );

  @override
  List<Object> get props => [
        loading,
        themeType,
        creatingRoom,
        searchResults,
      ];
}
