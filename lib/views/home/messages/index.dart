import 'package:Tether/domain/rooms/events/selectors.dart';
import 'package:Tether/domain/rooms/selectors.dart';
import 'package:Tether/global/colors.dart';
import 'package:Tether/global/formatters.dart';
import 'package:Tether/global/widgets/menu.dart';
import 'package:Tether/views/home/messages/message.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

// Store
import 'package:redux/redux.dart';
import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/rooms/events/actions.dart';

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
  final String photo;

  // Improve loading times
  MessageArguments({
    this.roomId,
    this.title,
    this.photo,
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
  onSendMessage({
    BuildContext context,
    Store<AppState> store,
    String roomId,
    String text,
  }) {
    if (text != null && text.length > 1) {
      store.dispatch(sendMessage(
        body: text,
        room: store.state.roomStore.rooms[roomId],
        type: 'm.room.message',
      ));
    }

    editorController.clear();
    FocusScope.of(context).unfocus();
  }

  Widget buildMessageList(
    BuildContext context,
    String roomId,
  ) =>
      StoreConnector<AppState, AppState>(
        converter: (Store<AppState> store) => store.state,
        builder: (context, state) {
          final messages = sortedMessages(
            room(id: roomId, state: state).messages,
          );
          final userId = state.userStore.user.userId;

          return ListView.builder(
            reverse: true,
            itemCount: messages.length,
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
              );
            },
          );
        },
      );

  Widget buildChatInput({
    BuildContext context,
    String roomId,
  }) =>
      StoreConnector<AppState, Store<AppState>>(
        converter: (Store<AppState> store) => store,
        builder: (context, store) {
          double width = MediaQuery.of(context).size.width;
          double messageInputWidth = width - 64;

          Color inputTextColor = const Color(BASICALLY_BLACK);
          Color inputColorBackground = const Color(ENABLED_GREY);

          if (Theme.of(context).brightness == Brightness.dark) {
            inputTextColor = Colors.white;
            inputColorBackground = Colors.blueGrey;
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Container(
                constraints: BoxConstraints(
                  maxWidth: messageInputWidth,
                ),
                child: TextField(
                  controller: editorController,
                  onChanged: (text) {
                    this.setState(() {
                      sendable = text != null && text.isNotEmpty;
                    });
                  },
                  onSubmitted: (text) => onSendMessage(
                    text: text,
                    roomId: roomId,
                    context: context,
                    store: store,
                  ),
                  // onEditingComplete: () {
                  //   print('they pressed it');
                  // },
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  focusNode: inputFieldNode,
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
                    hintText: 'Tether message',
                  ),
                ),
              ),
              Container(
                width: 48.0,
                padding: EdgeInsets.all(4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(48),
                  onTap: () => onSendMessage(
                    text: editorController.text,
                    roomId: roomId,
                    context: context,
                    store: store,
                  ),
                  child: CircleAvatar(
                    backgroundColor: PRIMARY_COLOR,
                    child: Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );

  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, Store<AppState>>(
        converter: (Store<AppState> store) => store,
        builder: (context, store) {
          final MessageArguments arguments =
              ModalRoute.of(context).settings.arguments;

          final isEditing = inputFieldNode.hasFocus;
          final isScrolling =
              messagesController.hasClients && messagesController.offset != 0;

          Color inputColor = Colors.white;

          if (Theme.of(context).brightness == Brightness.dark) {
            inputColor = BASICALLY_BLACK_COLOR;
          }
          return Scaffold(
            appBar: AppBar(
              brightness:
                  Brightness.dark, // TOOD: this should inherit from theme
              automaticallyImplyLeading: false,
              titleSpacing: 0.0,
              title: Row(children: <Widget>[
                Container(
                  margin: EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                IconButton(
                  icon: CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Text(
                      arguments.title.substring(0, 2).toUpperCase(),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                  tooltip: 'Profile and settings',
                ),
                Text(arguments.title,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w100)),
              ]),
              actions: <Widget>[
                RoundedPopupMenu<MessageOptions>(
                  onSelected: (MessageOptions result) {
                    print(result);
                    switch (result) {
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
            ),
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
                              arguments.roomId,
                            ),
                            Positioned(
                              // red box
                              child: Visibility(
                                visible: store.state.roomStore.loading,
                                child: Container(
                                    child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    // TODO: distinguish between loading and refreshing?
                                    // CircularProgressIndicator(
                                    //   strokeWidth: 4.0,
                                    //   backgroundColor: Colors.transparent,
                                    //   valueColor:
                                    //       new AlwaysStoppedAnimation<Color>(
                                    //     PRIMARY_COLOR,
                                    //   ),
                                    //   value: null,
                                    // ),
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
                    decoration: BoxDecoration(
                      color: inputColor,
                      boxShadow: isScrolling
                          ? [
                              BoxShadow(
                                blurRadius: 6,
                                offset: Offset(0, -4),
                                color: Colors.black12,
                              )
                            ]
                          : [],
                    ),
                    padding: EdgeInsets.only(
                      top: 12,
                      left: 8,
                      right: 8,
                      bottom: isEditing ? 12 : 48,
                    ),
                    child: buildChatInput(
                      context: context,
                      roomId: arguments.roomId,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}
