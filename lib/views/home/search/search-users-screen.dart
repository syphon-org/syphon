import 'package:equatable/equatable.dart';

import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:screenshot/screenshot.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/formatters.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/selectors.dart';
import 'package:syphon/store/search/actions.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/home/chat/chat-screen.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/widgets/appbars/appbar-search.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/dialogs/dialog-start-chat.dart';
import 'package:syphon/views/widgets/lists/list-item-user.dart';
import 'package:syphon/views/widgets/loader/index.dart';
import 'package:syphon/views/widgets/modals/modal-user-details.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({Key? key}) : super(key: key);

  @override
  SearchUserState createState() => SearchUserState();
}

class SearchUserState extends State<SearchUserScreen> {
  SearchUserState();

  final searchInputFocusNode = FocusNode();
  final avatarScrollController = ScrollController();

  String searchable = '';
  String? creatingRoomDisplayName;

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
    if (searchResults.isNotEmpty && searchResults[0] is! User) {
      store.dispatch(clearSearchResults());
    }
  }

  @override
  void dispose() {
    searchInputFocusNode.dispose();
    super.dispose();
  }

  @protected
  onShowUserDetails({required BuildContext context, User? user}) async {
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
  onCreateChat({required BuildContext context, required User user, _Props? props}) async {
    final store = StoreProvider.of<AppState>(context);

    final existingChatId = selectDirectChatIdExisting(
      state: store.state,
      user: user,
    );

    // Navigate to existing DM if one already exists
    if (existingChatId.isNotEmpty) {
      return Navigator.popAndPushNamed(
        context,
        Routes.chat,
        arguments: ChatScreenArguments(
          roomId: existingChatId,
          title: user.displayName,
        ),
      );
    }

    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) => DialogStartChat(
        user: user,
        title: Strings.titleDialogChatWithUser(formatUsername(user)),
        content: Strings.confirmStartChat,
        onStartChat: () async {
          setState(() {
            creatingRoomDisplayName = user.displayName;
          });
          final newRoomId = await props!.onCreateChatDirect(user: user);

          Navigator.pop(dialogContext);

          if (newRoomId != null) {
            Navigator.of(context).popAndPushNamed(
              Routes.chat,
              arguments: ChatScreenArguments(
                roomId: newRoomId,
                title: user.displayName,
              ),
            );
          }
        },
      ),
    );
  }

  ///
  /// Attempt User Chat
  ///
  /// attempt chating with a user by the name searched
  ///
  @protected
  onAttemptChat({required BuildContext context, required User user, _Props? props}) async {
    final store = StoreProvider.of<AppState>(context);

    final existingChatId = selectDirectChatIdExisting(
      state: store.state,
      user: user,
    );

    // Navigate to existing DM if one already exists
    if (existingChatId.isNotEmpty) {
      return Navigator.popAndPushNamed(
        context,
        Routes.chat,
        arguments: ChatScreenArguments(
          roomId: existingChatId,
          title: user.displayName,
        ),
      );
    }

    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) => DialogStartChat(
        user: user,
        title: Strings.titleDialogAttemptChatWithUser(formatUsername(user)),
        content: Strings.confirmAttemptChat,
        onStartChat: () async {
          setState(() {
            creatingRoomDisplayName = user.displayName;
          });
          final newRoomId =
              await props!.onCreateChatDirect(user: user, context: context);

          Navigator.pop(dialogContext);

          if (newRoomId != null) {
            Navigator.of(context).popAndPushNamed(
              Routes.chat,
              arguments: ChatScreenArguments(
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
  Widget buildSearchList(BuildContext context, _Props props) {
    final usersList = props.searchResults;

    final foundResult = props.searchResults.indexWhere(
      (result) => result.userId.contains(searchable),
    );

    final showManualUser = searchable.isNotEmpty && foundResult < 0;

    final attemptableUser = User(
      displayName: searchable,
      userId:
          searchable.isNotEmpty && searchable.contains(':') ? searchable : formatUserId(searchable),
    );

    return ListView(
      children: [
        Container(
          padding: EdgeInsets.only(left: 20, right: 20, top: 24),
          child: Row(
            children: [
              Text(
                Strings.labelSearchResults,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.subtitle2,
              ),
            ],
          ),
        ),
        Visibility(
          visible: showManualUser,
          child: GestureDetector(
            onTap: () => onAttemptChat(props: props, context: context, user: attemptableUser),
            child: ListItemUser(
              user: attemptableUser,
              currentUser: props.currentUser,
              enabled: creatingRoomDisplayName != searchable,
              loading: props.loading,
              real: false,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          itemCount: usersList.length,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            final user = usersList[index] as User;

            return GestureDetector(
              onTap: () => onShowUserDetails(context: context, user: user),
              child: ListItemUser(
                user: user,
                currentUser: props.currentUser,
                enabled: creatingRoomDisplayName != user.displayName,
                loading: props.loading,
                onPress: () => onCreateChat(
                  context: context,
                  props: props,
                  user: user,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @protected
  Widget buildPreviewList(BuildContext context, _Props props) {
    final usersList = props.usersRecent;
    final knownList = props.usersKnown;

    return ListView(
      children: [
        Visibility(
          visible: usersList.isNotEmpty,
          child: Container(
            padding: EdgeInsets.only(left: 20, right: 20, top: 24),
            child: Row(
              children: [
                Text(
                  Strings.labelUsersRecent,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.subtitle2,
                ),
              ],
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          itemCount: usersList.length,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            final user = usersList[index];

            return GestureDetector(
              onTap: () => onShowUserDetails(context: context, user: user),
              child: ListItemUser(
                user: user,
                currentUser: props.currentUser,
                enabled: creatingRoomDisplayName != user.displayName,
                loading: props.loading,
                onPress: () => onCreateChat(
                  context: context,
                  props: props,
                  user: user,
                ),
              ),
            );
          },
        ),
        Container(
          padding: EdgeInsets.only(left: 20, right: 20, top: 24),
          child: Row(
            children: [
              Text(
                Strings.labelKnownUsers,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.subtitle2,
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          itemCount: knownList.length,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            final user = knownList[index];

            return GestureDetector(
              onTap: () => onShowUserDetails(context: context, user: user),
              child: ListItemUser(
                user: user,
                currentUser: props.currentUser,
                enabled: creatingRoomDisplayName != user.displayName,
                loading: props.loading,
                onPress: () => onCreateChat(
                  context: context,
                  props: props,
                  user: user,
                ),
              ),
            );
          },
        ),
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
              label: Strings.labelSearchForUser,
              tooltip: Strings.tooltipSearchUsers,
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
                Visibility(
                  visible: searchable.isEmpty,
                  child: buildPreviewList(context, props),
                ),
                Visibility(
                  visible: searchable.isNotEmpty,
                  child: buildSearchList(context, props),
                ),
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
  final User currentUser;
  final List<User> usersRecent;
  final List<User> usersKnown;
  final List<dynamic> searchResults;

  final Function onSearch;
  final Function onCreateChatDirect;

  const _Props({
    required this.themeType,
    required this.loading,
    required this.creatingRoom,
    required this.searchResults,
    required this.currentUser,
    required this.usersRecent,
    required this.usersKnown,
    required this.onSearch,
    required this.onCreateChatDirect,
  });

  @override
  List<Object> get props => [
        loading,
        themeType,
        creatingRoom,
        searchResults,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        themeType: store.state.settingsStore.themeSettings.themeType,
        loading: store.state.searchStore.loading,
        creatingRoom: store.state.roomStore.loading,
        currentUser: store.state.authStore.currentUser,
        usersKnown: selectKnownUsers(store.state),
        usersRecent: selectFriendlyUsers(store.state),
        searchResults: store.state.searchStore.searchResults,
        onSearch: (String text) {
          if (text.contains('@') && text.length == 1) {
            return;
          }

          if (text.isEmpty) {
            return;
          }

          store.dispatch(searchUsers(searchText: text));
        },
        onCreateChatDirect: (
            {required User user, required BuildContext context}) async {
          if (user.userId == store.state.authStore.currentUser.userId) {
            //Note to self, create our Avatar
            final screenshotController = ScreenshotController();
            final avatar = MemoryFileSystem().file('avatar.png');

            await screenshotController
                .captureFromWidget(StoreProvider<AppState>(
                    store: store,
                    child: Avatar(
                      alt: Strings.labelNoteToSelf,
                      icon: Icons.sticky_note_2_outlined,
                      background: Theme.of(context).primaryColor,
                    )))
                .then((capturedAvatar) {
              avatar.writeAsBytesSync(capturedAvatar);
            });

            return store.dispatch(
              createRoom(
                isDirect: true,
                invites: <User>[user],
                avatarFile: avatar,
              ),
            );
          }

          return store.dispatch(
            createRoom(
              isDirect: true,
              invites: <User>[user],
            ),
          );
        },
      );
}
