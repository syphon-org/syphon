import 'package:equatable/equatable.dart';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/svg.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/room/selectors.dart';
import 'package:syphon/store/search/actions.dart';
import 'package:syphon/store/settings/chat-settings/model.dart';
import 'package:syphon/store/settings/chat-settings/selectors.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/widgets/appbars/appbar-search.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/dialogs/dialog-start-chat.dart';
import 'package:syphon/views/widgets/lifecycle.dart';
import 'package:syphon/views/widgets/loader/index.dart';

class ChatSearchArguments {
  User? user;
  ChatSearchArguments({this.user});
}

class ChatSearchScreen extends StatefulWidget {
  const ChatSearchScreen({Key? key}) : super(key: key);

  @override
  ChatSearchState createState() => ChatSearchState();
}

class ChatSearchState extends State<ChatSearchScreen> with Lifecycle<ChatSearchScreen> {
  final searchInputFocusNode = FocusNode();

  ChatSearchState();

  @override
  onMounted() async {
    final store = StoreProvider.of<AppState>(context);
    final searchResults = store.state.searchStore.searchResults;

    // Clear search if previous results are not from User searching
    if (searchResults.isNotEmpty && searchResults[0] is! Room) {
      store.dispatch(clearSearchResults());
    }

    // Initial search to show rooms by most popular
    if (store.state.searchStore.searchResults.isEmpty) {
      store.dispatch(searchRooms(searchText: ''));
    }
  }

  @protected
  Future onInviteUser(_Props props, Room room) async {
    FocusScope.of(context).unfocus();

    final ChatSearchArguments arguments =
        ModalRoute.of(context)!.settings.arguments as ChatSearchArguments;
    final user = arguments.user!;
    final username = formatUsername(user);

    return showDialog(
      context: context,
      builder: (BuildContext context) => DialogStartChat(
        user: user,
        title: 'Invite $username',
        content: '${Strings.confirmInvite}\n\nUser: $username\nRoom: ${room.name}',
        action: 'send invite',
        onStartChat: () async {
          props.onSendInvite(room: room, user: user);
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    searchInputFocusNode.dispose();
    super.dispose();
  }

  @protected
  Widget buildRoomList(BuildContext context, _Props props) {
    final store = StoreProvider.of<AppState>(context);
    final rooms = props.searchResults as List<Room>;

    if (rooms.isEmpty) {
      return Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            constraints: BoxConstraints(
              minWidth: Dimensions.mediaSizeMin,
              maxWidth: Dimensions.mediaSizeMax,
              maxHeight: Dimensions.mediaSizeMin,
            ),
            child: SvgPicture.asset(
              Assets.heroChatNotFound,
              semanticsLabel: Strings.semanticsHomeDefault,
            ),
          ),
          GestureDetector(
            child: Container(
              margin: EdgeInsets.only(bottom: 48),
              padding: EdgeInsets.only(top: 16),
              child: Text(
                Strings.labelMessagesEmpty,
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ],
      ));
    }

    return ListView.builder(
      scrollDirection: Axis.vertical,
      itemCount: rooms.length,
      itemBuilder: (BuildContext context, int index) {
        final room = rooms[index];

        var previewStyle;
        var preview = room.topic;
        final backgroundColor = selectChatColor(store, room.id);

        if (preview == null || preview.isEmpty) {
          preview = 'No Description';
          previewStyle = TextStyle(fontStyle: FontStyle.italic);
        }

        // GestureDetector w/ animation
        return InkWell(
          onTap: () => onInviteUser(props, room),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: Theme.of(context).textTheme.subtitle1!.fontSize!,
            ).add(Dimensions.appPaddingHorizontal),
            child: Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      Avatar(
                        uri: room.avatarUri,
                        size: Dimensions.avatarSizeMin,
                        alt: formatRoomInitials(room: room),
                        background: backgroundColor,
                      ),
                      Visibility(
                        visible: room.encryptionEnabled,
                        child: Positioned(
                          bottom: 0,
                          right: 0,
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: Dimensions.badgeAvatarSize,
                                height: Dimensions.badgeAvatarSize,
                                color: Colors.green,
                                child: Icon(
                                  Icons.lock,
                                  color: Colors.white,
                                  size: Dimensions.iconSizeMini,
                                ),
                              )),
                        ),
                      ),
                      Visibility(
                        visible: room.invite,
                        child: Positioned(
                          bottom: 0,
                          right: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: Dimensions.badgeAvatarSize,
                              height: Dimensions.badgeAvatarSize,
                              color: Colors.grey,
                              child: Icon(
                                Icons.mail_outline,
                                color: Colors.white,
                                size: Dimensions.iconSizeMini,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: room.type == 'group' && !room.invite,
                        child: Positioned(
                          right: 0,
                          bottom: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: Dimensions.badgeAvatarSize,
                              height: Dimensions.badgeAvatarSize,
                              color: Theme.of(context).scaffoldBackgroundColor,
                              child: Icon(
                                Icons.group,
                                color: Theme.of(context).iconTheme.color,
                                size: Dimensions.badgeAvatarSizeSmall,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: room.type == 'public' && !room.invite,
                        child: Positioned(
                          right: 0,
                          bottom: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: Dimensions.badgeAvatarSize,
                              height: Dimensions.badgeAvatarSize,
                              color: Theme.of(context).scaffoldBackgroundColor,
                              child: Icon(
                                Icons.public,
                                color: Theme.of(context).iconTheme.color,
                                size: Dimensions.badgeAvatarSize,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  flex: 1,
                  fit: FlexFit.tight,
                  child: Flex(
                    direction: Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              room.name!,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyText1,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.caption!.merge(
                              previewStyle,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStateToProps(store),
      builder: (context, props) {
        final ChatSearchArguments arguments =
            ModalRoute.of(context)!.settings.arguments as ChatSearchArguments;
        return Scaffold(
          appBar: AppBarSearch(
            title: '${Strings.titleInvite} ${formatUsername(arguments.user!)}',
            label: 'Search any room info...',
            tooltip: 'Search Joined Rooms',
            forceFocus: true,
            focusNode: searchInputFocusNode,
            onSearch: (text) {
              props.onSearch(text);
            },
          ),
          body: Center(
            child: Stack(
              children: [
                buildRoomList(context, props),
                Positioned(
                  child: Loader(
                    loading: props.loading,
                  ),
                ),
              ],
            ),
          ),
        );
      });
}

class _Props extends Equatable {
  final bool loading;
  final ThemeType themeType;
  final List<dynamic> searchResults;
  final Map<String, ChatSetting> chatSettings;

  final Function onSearch;
  final Function onSendInvite;

  const _Props({
    required this.themeType,
    required this.loading,
    required this.searchResults,
    required this.chatSettings,
    required this.onSearch,
    required this.onSendInvite,
  });

  @override
  List<Object> get props => [
        themeType,
        loading,
        searchResults,
        chatSettings,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        themeType: store.state.settingsStore.themeSettings.themeType,
        loading: store.state.searchStore.loading,
        searchResults: store.state.searchStore.searchResults,
        chatSettings: store.state.settingsStore.chatSettings,
        onSearch: (text) {
          store.dispatch(searchRooms(searchText: text));
        },
        onSendInvite: ({Room? room, User? user}) {
          store.dispatch(inviteUser(room: room, user: user));
        },
      );
}
