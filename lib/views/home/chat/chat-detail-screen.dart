import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/selectors.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/selectors.dart';
import 'package:syphon/store/settings/chat-settings/actions.dart';
import 'package:syphon/store/settings/chat-settings/selectors.dart';
import 'package:syphon/store/settings/notification-settings/actions.dart';
import 'package:syphon/store/settings/notification-settings/model.dart';
import 'package:syphon/store/settings/notification-settings/options/types.dart';
import 'package:syphon/store/user/actions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/home/chat/chat-detail-all-users-screen.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';
import 'package:syphon/views/widgets/dialogs/dialog-color-picker.dart';
import 'package:syphon/views/widgets/dialogs/dialog-confirm.dart';
import 'package:syphon/views/widgets/lifecycle.dart';
import 'package:syphon/views/widgets/lists/list-user-bubbles.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

class ChatDetailsArguments {
  final String? roomId;
  final String? title;

  ChatDetailsArguments({
    this.roomId,
    this.title,
  });
}

class ChatDetailsScreen extends StatefulWidget {
  const ChatDetailsScreen({Key? key}) : super(key: key);

  @override
  ChatDetailsState createState() => ChatDetailsState();
}

class ChatDetailsState extends State<ChatDetailsScreen> with Lifecycle<ChatDetailsScreen> {
  ChatDetailsState() : super();

  final ScrollController scrollController = ScrollController(
    initialScrollOffset: 0,
  );

  final double headerSize = 54;

  double headerOpacity = 1;
  List<User>? usersList;

  @override
  void initState() {
    super.initState();

    scrollController.addListener(() {
      final height = MediaQuery.of(context).size.height;
      const minOffset = 0;
      final maxOffset = height * 0.2;
      final offsetRatio = scrollController.offset / maxOffset;

      final isOpaque = scrollController.offset <= minOffset;
      final isTransparent = scrollController.offset > maxOffset;
      final isFading = !isOpaque && !isTransparent;

      if (isFading) {
        return setState(() {
          headerOpacity = 1 - offsetRatio;
        });
      }

      if (isTransparent) {
        return setState(() {
          headerOpacity = 0;
        });
      }

      return setState(() {
        headerOpacity = 1;
      });
    });
  }

  @override
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);
    final arguments = ModalRoute.of(context)!.settings.arguments as ChatDetailsArguments?;

    if (arguments?.roomId == null) return;

    store.dispatch(LoadUsers(
      userIds: selectRoom(id: arguments!.roomId, state: store.state).userIds,
    ));
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
  }

  onBlockUser({required BuildContext context, required _Props props}) async {
    final user = props.users.firstWhere(
      (user) => user!.userId != props.currentUser.userId,
    );
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => DialogConfirm(
        title: Strings.buttonBlockUser,
        content: Strings.confirmBlockUser(user?.displayName),
        onConfirm: () async {
          await props.onBlockUser(user);
          Navigator.popUntil(context, (route) => route.isFirst);
        },
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  onShowColorPicker({
    required BuildContext context,
    required int originalColor,
    required Function onSelectColor,
  }) async =>
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) => DialogColorPicker(
          title: Strings.titleDialogChatColor,
          currentColor: originalColor,
          onSelectColor: onSelectColor,
        ),
      );

  onLeaveChat(_Props props) async {
    showDialog(
      context: context,
      builder: (dialogContext) => DialogConfirm(
        title: Strings.buttonLeaveChat.capitalize(),
        confirmText: Strings.buttonLeaveChat.capitalize(),
        confirmStyle: TextStyle(color: Colors.red),
        content: Strings.confirmLeaveRooms(rooms: [props.room]),
        onDismiss: () => Navigator.pop(dialogContext),
        onConfirm: () async {
          await props.onLeaveChat();
          Navigator.popUntil(context, (route) => route.isFirst);
          Navigator.pop(dialogContext);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    // Confirm this is needed in chat details
    final titlePadding = Dimensions.listTitlePaddingDynamic(width: width);
    final contentPadding = Dimensions.listPaddingDynamic(width: width);

    final ChatDetailsArguments? arguments =
        ModalRoute.of(context)!.settings.arguments as ChatDetailsArguments?;

    final scaffordBackgroundColor = Theme.of(context).brightness == Brightness.light
        ? Color(Colours.greyLightest)
        : Theme.of(context).scaffoldBackgroundColor;

    return StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStateToProps(
        store,
        arguments?.roomId,
      ),
      builder: (context, props) {
        var notificationsEnabled = props.notificationSettings.toggleType == ToggleType.Enabled;

        if (props.notificationOptions != null) {
          notificationsEnabled = props.notificationOptions?.enabled ?? false;
        }

        return Scaffold(
          backgroundColor: scaffordBackgroundColor,
          body: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: height * 0.3,
                systemOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
                automaticallyImplyLeading: false,
                titleSpacing: 0.0,
                title: Row(
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        arguments!.title!,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                flexibleSpace: Hero(
                  tag: 'ChatAvatar',
                  child: Container(
                    padding: EdgeInsets.only(top: height * 0.075),
                    color: props.chatColorPrimary,
                    width: width,
                    child: OverflowBox(
                      minHeight: 64,
                      maxHeight: height * 0.3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Opacity(
                            opacity: headerOpacity,
                            child: Avatar(
                              size: height * 0.15,
                              uri: props.room.avatarUri,
                              alt: props.room.name,
                              background: props.chatColorPrimary,
                              rebuild: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverList(
                  delegate: SliverChildListDelegate([
                Container(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: <Widget>[
                      CardSection(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        margin: EdgeInsets.only(bottom: 4),
                        child: Column(
                          children: [
                            Container(
                              width: width,
                              padding: titlePadding,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        Strings.labelUsers,
                                        textAlign: TextAlign.start,
                                        style: Theme.of(context).textTheme.subtitle2,
                                      ),
                                    ],
                                  ),
                                  TouchableOpacity(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        Routes.chatUsers,
                                        arguments: ChatUsersDetailArguments(
                                          roomId: props.room.id,
                                        ),
                                      );
                                    },
                                    activeOpacity: 0.4,
                                    child: Row(
                                      children: [
                                        Text(
                                          Strings.buttonTextSeeAllUsers,
                                          textAlign: TextAlign.start,
                                        ),
                                        Text(
                                          ' (${props.room.userIds.length > props.usersTotal ? props.room.userIds.length : props.usersTotal})',
                                          textAlign: TextAlign.start,
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: width,
                                maxHeight: Dimensions.avatarSizeLarge,
                              ),
                              child: ListUserBubbles(
                                users: props.users,
                                roomId: props.room.id,
                                forceOption: props.users.length < props.room.totalJoinedUsers,
                              ),
                            )
                          ],
                        ),
                      ),
                      CardSection(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: width,
                              padding: titlePadding,
                              child: Text(
                                Strings.labelAbout,
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.subtitle2,
                              ),
                            ),
                            Container(
                              padding: contentPadding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    props.room.name!,
                                    textAlign: TextAlign.start,
                                    style: Theme.of(context).textTheme.headline6,
                                  ),
                                  Text(
                                    props.room.id,
                                    textAlign: TextAlign.start,
                                    style: Theme.of(context).textTheme.caption,
                                  ),
                                  Text(
                                    props.room.type,
                                    textAlign: TextAlign.start,
                                    style: Theme.of(context).textTheme.caption,
                                  ),
                                  Visibility(
                                    visible:
                                        props.room.topic != null && props.room.topic!.isNotEmpty,
                                    child: Container(
                                      padding: EdgeInsets.only(top: 12),
                                      child: Text(
                                        props.room.topic!,
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      CardSection(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Container(
                              width: width,
                              padding: contentPadding,
                              child: Text(
                                Strings.labelChatSettings,
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.subtitle2,
                              ),
                            ),
                            ListTile(
                              contentPadding: contentPadding,
                              title: Text(
                                Strings.labelColor,
                                style: Theme.of(context).textTheme.subtitle1,
                              ),
                              trailing: Container(
                                padding: EdgeInsets.only(right: 8),
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: props.chatColorPrimary,
                                ),
                              ),
                              onTap: () => onShowColorPicker(
                                context: context,
                                onSelectColor: props.onSelectPrimaryColor,
                                originalColor: props.chatColorPrimary.value,
                              ),
                            ),
                            ListTile(
                              enabled: !props.loading,
                              contentPadding: contentPadding,
                              title: Text(
                                Strings.listItemChatDetailToggleDirectChat,
                                style: Theme.of(context).textTheme.subtitle1,
                              ),
                              trailing: Switch(
                                value: props.room.direct,
                                onChanged: (value) {
                                  props.onToggleDirectRoom();
                                },
                              ),
                              onTap: () {
                                props.onToggleDirectRoom();
                              },
                            ),
                          ],
                        ),
                      ),
                      CardSection(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Container(
                              width: width,
                              padding: contentPadding,
                              child: Text(
                                Strings.listItemChatDetailNotificationSetting,
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.subtitle2,
                              ),
                            ),
                            ListTile(
                              onTap: () => props.onToggleRoomNotifications(),
                              contentPadding: contentPadding,
                              title: Text(
                                Strings.listItemChatDetailNotifications,
                              ),
                              trailing: Switch(
                                value: notificationsEnabled,
                                onChanged: (_) => props.onToggleRoomNotifications(),
                              ),
                            ),
                            ListTile(
                              enabled: false,
                              contentPadding: contentPadding,
                              title: Text(
                                Strings.listItemChatDetailVibrate,
                              ),
                              trailing: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  Strings.labelDefault,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(color: Colors.grey),
                                ),
                              ),
                            ),
                            ListTile(
                              enabled: false,
                              contentPadding: contentPadding,
                              title: Text(
                                Strings.listItemChatDetailNotificationSound,
                              ),
                              trailing: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  Strings.placeholderDefaultRoomNotification,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(color: Colors.grey),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CardSection(
                        child: Column(
                          children: [
                            Container(
                              width: width,
                              padding: contentPadding,
                              child: Text(
                                Strings.listItemChatDetailPrivacyStatus,
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.subtitle2,
                              ),
                            ),
                            ListTile(
                              enabled: false,
                              contentPadding: contentPadding,
                              title: Text(
                                Strings.listItemChatDetailViewKey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CardSection(
                        child: Container(
                          child: Column(
                            children: [
                              Visibility(
                                visible: props.room.direct,
                                child: ListTile(
                                  onTap: () => onBlockUser(
                                    context: context,
                                    props: props,
                                  ),
                                  contentPadding: contentPadding,
                                  title: Text(
                                    Strings.buttonBlockUser,
                                    style: Theme.of(context).textTheme.subtitle1!.copyWith(
                                          color: Colors.redAccent,
                                        ),
                                  ),
                                ),
                              ),
                              ListTile(
                                onTap: () => onLeaveChat(props),
                                contentPadding: contentPadding,
                                title: Text(
                                  Strings.buttonLeaveChat,
                                  style: Theme.of(context).textTheme.subtitle1!.copyWith(
                                        color: Colors.redAccent,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ])),
            ],
          ),
        );
      },
    );
  }
}

class _Props extends Equatable {
  final Room room;
  final bool loading;
  final User currentUser;
  final int usersTotal;
  final List<User?> users;
  final Color chatColorPrimary;
  final List<Message> messages;
  final NotificationOptions? notificationOptions;
  final NotificationSettings notificationSettings;

  final Function onLeaveChat;
  final Function onBlockUser;
  final Function onSelectPrimaryColor;
  final Function onToggleDirectRoom;
  final Function onToggleRoomNotifications;
  // final Function onViewEncryptionKeys;

  const _Props({
    required this.room,
    required this.users,
    required this.loading,
    required this.messages,
    required this.usersTotal,
    required this.currentUser,
    required this.onBlockUser,
    required this.onLeaveChat,
    required this.chatColorPrimary,
    required this.onSelectPrimaryColor,
    required this.onToggleDirectRoom,
    required this.notificationOptions,
    required this.notificationSettings,
    required this.onToggleRoomNotifications,
    // @required this.onViewEncryptionKeys,
  });

  @override
  List<Object> get props => [
        room,
        users,
        messages,
        chatColorPrimary,
        loading,
      ];

  static _Props mapStateToProps(Store<AppState> store, String? roomId) => _Props(
      loading: store.state.roomStore.loading,
      notificationSettings: store.state.settingsStore.notificationSettings,
      notificationOptions:
          store.state.settingsStore.notificationSettings.notificationOptions[roomId],
      room: selectRoom(id: roomId, state: store.state),
      users: roomUsers(store.state, roomId),
      usersTotal: selectRoom(id: roomId, state: store.state).totalJoinedUsers > 0
          ? selectRoom(id: roomId, state: store.state).totalJoinedUsers
          : roomUsers(store.state, roomId).length,
      currentUser: store.state.authStore.user,
      messages: roomMessages(store.state, roomId),
      onToggleRoomNotifications: () async {
        if (roomId != null) {
          await store.dispatch(toggleChatNotifications(roomId: roomId));
        }
      },
      onBlockUser: (User user) async {
        await store.dispatch(toggleBlockUser(user: user));
      },
      onLeaveChat: () async {
        await store.dispatch(leaveRoom(
          room: selectRoom(state: store.state, id: roomId),
        ));
      },
      chatColorPrimary: selectChatColor(store, roomId),
      onSelectPrimaryColor: (color) {
        store.dispatch(updateRoomPrimaryColor(
          roomId: roomId,
          color: color,
        ));
      },
      onToggleDirectRoom: () {
        final room = selectRoom(id: roomId, state: store.state);
        store.dispatch(toggleDirectRoom(room: room, enabled: !room.direct));
      });
}
