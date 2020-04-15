import 'dart:io';

// Domain
import 'package:Tether/domain/rooms/room/model.dart';
import 'package:Tether/global/themes.dart';
import 'package:Tether/views/home/messages/settings.dart';
import 'package:Tether/views/widgets/chat-avatar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

// Store
import 'package:redux/redux.dart';
import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/rooms/events/model.dart';
import 'package:Tether/domain/rooms/events/selectors.dart';
import 'package:Tether/domain/rooms/selectors.dart' as roomSelectors;
import 'package:Tether/domain/rooms/events/actions.dart';

// Global widgets
import 'package:Tether/views/widgets/message.dart';

// Styling
import 'package:Tether/global/colors.dart';
import 'package:Tether/views/widgets/menu.dart';

/**
 * Resources:
 * https://stackoverflow.com/questions/45900387/multi-line-textfield-in-flutter
 * https://stackoverflow.com/questions/50400529/how-to-update-flutter-textfields-height-and-width
 * https://stackoverflow.com/questions/55863766/how-to-prevent-keyboard-from-dismissing-on-pressing-submit-key-in-flutter
 * https://medium.com/nonstopio/make-the-list-auto-scrollable-when-you-add-the-new-message-in-chat-messages-functionality-in-19e457a838a7
 * 
 */
enum MessageOptions {
  search,
  allMedia,
  chatSettings,
  inviteFriends,
  muteNotifications
}

class MessageArguments {
  final String roomId;
  final String title;

  // Improve loading times
  MessageArguments({
    this.roomId,
    this.title,
  });
}

class Messages extends StatefulWidget {
  const Messages({Key key}) : super(key: key);

  @override
  MessagesState createState() => MessagesState();
}

class MessagesState extends State<Messages> {
  FocusNode inputFieldNode;
  Map<String, Color> senderColors;

  bool sendable = false;
  Message selectedMessage;
  final editorController = TextEditingController();
  final messagesController = ScrollController(initialScrollOffset: 0);

  @override
  void initState() {
    super.initState();
    inputFieldNode = FocusNode();
    // WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  @override
  void dispose() {
    inputFieldNode.dispose();
    super.dispose();
  }

  @protected
  onToggleMessageOptions({Message message}) {
    this.setState(() {
      selectedMessage = message;
    });
  }

  onDismissMessageOptions() {
    this.setState(() {
      selectedMessage = null;
    });
  }

  // TODO: I like having this top level, but it's a nightmare to pass in vars
  // if passed through navigator (ModalRoute) args
  // @protected
  // onSendMessage({
  //   Function sendMessage,
  //   String roomId,
  //   String text,
  // }) {
  //   if (sendMessage != null) {
  //     sendMessage();
  //   }
  //   editorController.clear();
  //   FocusScope.of(context).unfocus();
  // }

  /** TODO: should these have their own connectors?
   *    
        StoreConnector<AppState, _Props>(
        distinct: true,
        rebuildOnChange: false,
        converter: (Store<AppState> store) => _Props.mapStoreToProps(
          store, 
        ),
        builder: (context, props) {
   */
  Widget buildMessageList(
    BuildContext context,
    _Props props,
  ) {
    final messages = props.messages;
    final userId = props.userId;

    return GestureDetector(
      onTap: onDismissMessageOptions,
      child: ListView.builder(
        reverse: true,
        itemCount: messages.length,
        padding: EdgeInsets.only(bottom: 8),
        scrollDirection: Axis.vertical,
        controller: messagesController,
        itemBuilder: (BuildContext context, int index) {
          final message = messages[index];
          final lastMessage = index != 0 ? messages[index - 1] : null;
          final nextMessage =
              index + 1 < messages.length ? messages[index + 1] : null;

          final isLastSender =
              lastMessage != null && lastMessage.sender == message.sender;
          final isNextSender =
              nextMessage != null && nextMessage.sender == message.sender;
          final isUserSent = userId == message.sender;

          return MessageWidget(
            message: message,
            isUserSent: isUserSent,
            isLastSender: isLastSender,
            isNextSender: isNextSender,
            onLongPress: onToggleMessageOptions,
            theme: props.theme,
          );
        },
      ),
    );
  }

  /**
   *    
        StoreConnector<AppState, _Props>(
        distinct: true,
        rebuildOnChange: false,
        converter: (Store<AppState> store) => _Props.mapStoreToProps(
          store, 
        ),
        builder: (context, props) {
   */
  Widget buildChatInput(
    BuildContext context,
    _Props props,
  ) {
    double width = MediaQuery.of(context).size.width;
    double messageInputWidth = width - 72;

    Color inputTextColor = const Color(BASICALLY_BLACK);
    Color inputColorBackground = const Color(ENABLED_GREY);
    Color inputCursorColor = Colors.blueGrey;
    Color sendButtonColor = const Color(DISABLED_GREY);

    if (sendable) {
      sendButtonColor = const Color(TETHERED_CYAN);
    }

    if (Theme.of(context).brightness == Brightness.dark) {
      inputTextColor = Colors.white;
      inputColorBackground = Colors.blueGrey;
      inputCursorColor = Colors.white;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Container(
          constraints: BoxConstraints(
            maxHeight: 46,
            maxWidth: messageInputWidth,
          ),
          child: TextField(
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            cursorColor: inputCursorColor,
            focusNode: inputFieldNode,
            controller: editorController,
            onChanged: (text) {
              this.setState(() {
                sendable = text != null && text.isNotEmpty;
              });
            },
            onSubmitted: (text) {
              props.onSendMessage(
                body: editorController.text,
                roomId: props.room.id,
              );
              editorController.clear();
              FocusScope.of(context).unfocus();
            },
            style: TextStyle(
              height: 1.5,
              color: inputTextColor,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: inputColorBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20.0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.0),
              ),
              hintText: 'Matrix message',
            ),
          ),
        ),
        Container(
          width: 48.0,
          padding: EdgeInsets.symmetric(vertical: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(48),
            onTap: sendable
                ? () {
                    props.onSendMessage(
                      body: editorController.text,
                      roomId: props.room.id,
                    );
                    editorController.clear();
                    FocusScope.of(context).unfocus();
                  }
                : null,
            child: CircleAvatar(
              backgroundColor: sendButtonColor,
              child: Icon(
                Icons.send,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @protected
  buildRoomAppBar({
    _Props props,
    BuildContext context,
  }) {
    return AppBar(
      brightness: Brightness.dark, // TOOD: this should inherit from theme
      automaticallyImplyLeading: false,
      titleSpacing: 0.0,
      title: Row(
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(left: 8),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context, false),
            ),
          ),
          GestureDetector(
            child: Hero(
              tag: "ChatAvatar",
              child: Container(
                padding: EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: props.room.avatar != null
                      ? Colors.transparent
                      : Colors.grey,
                  child: buildChatAvatar(
                    room: props.room,
                  ),
                ),
              ),
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/home/messages/settings',
                arguments: ChatSettingsArguments(
                  roomId: props.room.id,
                  title: props.room.name,
                ),
              );
            },
          ),
          Text(props.room.name,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w100)),
        ],
      ),
      actions: <Widget>[
        RoundedPopupMenu<MessageOptions>(
          onSelected: (MessageOptions result) {
            print(result);
            switch (result) {
              case MessageOptions.chatSettings:
                return Navigator.pushNamed(
                  context,
                  '/home/messages/settings',
                  arguments: ChatSettingsArguments(
                    roomId: props.room.id,
                    title: props.room.name,
                  ),
                );
              default:
                break;
            }
          },
          icon: Icon(Icons.more_vert, color: Colors.white),
          itemBuilder: (BuildContext context) =>
              <PopupMenuEntry<MessageOptions>>[
            const PopupMenuItem<MessageOptions>(
              value: MessageOptions.search,
              child: Text('Search'),
            ),
            const PopupMenuItem<MessageOptions>(
              value: MessageOptions.allMedia,
              child: Text('All Media'),
            ),
            const PopupMenuItem<MessageOptions>(
              value: MessageOptions.chatSettings,
              child: Text('Chat Settings'),
            ),
            const PopupMenuItem<MessageOptions>(
              value: MessageOptions.inviteFriends,
              child: Text('Invite Friends'),
            ),
            const PopupMenuItem<MessageOptions>(
              value: MessageOptions.muteNotifications,
              child: Text('Mute Notifications'),
            ),
          ],
        )
      ],
    );
  }

  @protected
  buildMessageAppBar({
    _Props props,
    BuildContext context,
  }) {
    return AppBar(
      brightness: Brightness.dark, // TOOD: this should inherit from theme
      backgroundColor: Colors.grey[500],
      automaticallyImplyLeading: false,
      titleSpacing: 0.0,
      title: Row(
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(left: 8),
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: onDismissMessageOptions,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.info),
          tooltip: 'Message Details',
          color: Colors.white,
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.delete),
          iconSize: 28.0,
          tooltip: 'Delete Message',
          color: Colors.white,
          onPressed: () => props.onDeleteMessage(
            message: this.selectedMessage,
          ),
        ),
        IconButton(
          icon: Icon(Icons.content_copy),
          iconSize: 22.0,
          tooltip: 'Copy Message Content',
          color: Colors.white,
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.reply),
          iconSize: 28.0,
          tooltip: 'Quote and Reply',
          color: Colors.white,
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.share),
          iconSize: 24.0,
          tooltip: 'Search Chats',
          color: Colors.white,
          onPressed: () {},
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStoreToProps(
          store,
          (ModalRoute.of(context).settings.arguments as MessageArguments)
              .roomId,
        ),
        builder: (context, props) {
          final closedInputPadding = !inputFieldNode.hasFocus && Platform.isIOS;
          final isScrolling =
              messagesController.hasClients && messagesController.offset != 0;

          Color inputContainerColor = Colors.white;

          if (Theme.of(context).brightness == Brightness.dark) {
            inputContainerColor = Colors.grey[850];
          }

          var currentAppBar = buildRoomAppBar(
            props: props,
            context: context,
          );
          if (this.selectedMessage != null) {
            currentAppBar = buildMessageAppBar(
              props: props,
              context: context,
            );
          }

          return Scaffold(
            appBar: currentAppBar,
            body: Align(
              alignment: Alignment.topRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () {
                        // TODO: refresh sync?
                        return Future.value();
                      },
                      child: GestureDetector(
                        onTap: () {
                          // Disimiss keyboard if they click outside the text input
                          FocusScope.of(context).unfocus();
                        },
                        child: Stack(
                          children: [
                            buildMessageList(
                              context,
                              props,
                            ),
                            Positioned(
                              // red box
                              child: Visibility(
                                visible: props.roomsLoading,
                                child: Container(
                                    child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    RefreshProgressIndicator(
                                      strokeWidth: 2.0,
                                      valueColor:
                                          new AlwaysStoppedAnimation<Color>(
                                        PRIMARY_COLOR,
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
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(
                      top: 12,
                      left: 8,
                      right: 8,
                      bottom: 12,
                    ),
                    decoration: BoxDecoration(
                      color: inputContainerColor,
                      boxShadow: isScrolling
                          ? [
                              BoxShadow(
                                  blurRadius: 6,
                                  offset: Offset(0, -4),
                                  color: Colors.black12)
                            ]
                          : [],
                    ),
                    child: AnimatedPadding(
                      duration: Duration(
                          milliseconds: inputFieldNode.hasFocus ? 225 : 0),
                      padding: EdgeInsets.only(
                        bottom: closedInputPadding ? 48 : 0,
                      ),
                      child: buildChatInput(
                        context,
                        props,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _Props {
  final Room room;
  final String userId;
  final List<Message> messages;
  final List<Message> outbox;
  final bool roomsLoading;
  final ThemeType theme;

  final Function onSendMessage;
  final Function onDeleteMessage;

  _Props({
    @required this.room,
    @required this.theme,
    @required this.userId,
    @required this.messages,
    @required this.outbox,
    @required this.roomsLoading,
    @required this.onSendMessage,
    @required this.onDeleteMessage,
  });

  static _Props mapStoreToProps(Store<AppState> store, String roomId) => _Props(
        userId: store.state.userStore.user.userId,
        theme: store.state.settingsStore.theme,
        room: roomSelectors.room(
          id: roomId,
          state: store.state,
        ),
        messages: latestMessages(
          wrapOutboxMessages(
            messages:
                roomSelectors.room(id: roomId, state: store.state).messages,
            outbox: roomSelectors.room(id: roomId, state: store.state).outbox,
          ),
        ),
        roomsLoading: store.state.roomStore.loading,
        onDeleteMessage: ({
          Message message,
        }) {
          if (message != null) {
            store.dispatch(deleteMessage(message: message));
          }
        },
        onSendMessage: ({
          String roomId,
          String body,
        }) {
          if (body != null && body.length > 1) {
            store.dispatch(sendMessage(
              body: body,
              room: store.state.roomStore.rooms[roomId],
              type: 'm.room.message',
            ));
          }
        },
      );

  @override
  int get hashCode =>
      userId.hashCode ^ messages.hashCode ^ roomsLoading.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Props &&
          runtimeType == other.runtimeType &&
          messages == other.messages &&
          userId == other.userId &&
          roomsLoading == other.roomsLoading;
}
