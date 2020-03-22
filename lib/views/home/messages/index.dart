import 'package:Tether/domain/rooms/selectors.dart';
import 'package:Tether/global/colors.dart';
import 'package:Tether/global/formatters.dart';
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
enum Overflow {
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
  final messagesController = ScrollController();

  @override
  void initState() {
    super.initState();
    inputFieldNode = FocusNode();
  }

  @override
  void dispose() {
    inputFieldNode.dispose();
    super.dispose();
  }

  Widget buildMessageList(String roomId, BuildContext context) {
    return StoreConnector<AppState, AppState>(
      converter: (Store<AppState> store) => store.state,
      builder: (context, state) {
        final messages = room(id: roomId, state: state).messages;
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

            final userSent = userId == message.sender;

            var textColor = Colors.white;
            var backgroundColor = Colors.blue;
            var bubbleBorder = BorderRadius.circular(16);
            var messageAlignment = CrossAxisAlignment.start;
            var bubbleSpacing = EdgeInsets.symmetric(vertical: 8);

            if (isLastSender) {
              if (isNextSender) {
                // Message in the middle of a sender messages block
                bubbleSpacing = EdgeInsets.symmetric(vertical: 2);
                bubbleBorder = BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                );
              } else {
                // Message at the beginning of a sender messages block
                bubbleSpacing = EdgeInsets.only(top: 8, bottom: 2);
                bubbleBorder = BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                );
              }
            }

            if (!isLastSender && isNextSender) {
              // End of a sender messages block
              bubbleSpacing = EdgeInsets.only(top: 2, bottom: 8);
              bubbleBorder = BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                topLeft: Radius.circular(4),
              );
            }

            if (userSent) {
              textColor = GREY_DARK_COLOR;
              backgroundColor = ENABLED_GREY_COLOR;
              messageAlignment = CrossAxisAlignment.end;
            }

            /**
             * Text(
                message.body,
                textAlign: textAlign,
                style: TextStyle(),
              ),
             */
            return Container(
              child: Flex(
                direction: Axis.vertical,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: messageAlignment,
                children: <Widget>[
                  Container(
                    margin: bubbleSpacing,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    // decoration: BoxDecoration( // DEBUG ONLY
                    //   color: Colors.red,
                    // ),
                    child: Flex(
                        direction: Axis.horizontal,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Visibility(
                            visible: !isLastSender,
                            maintainState: true,
                            maintainAnimation: true,
                            maintainSize: true,
                            child: Container(
                              margin: const EdgeInsets.only(
                                right: 12,
                              ),
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: backgroundColor,
                                child: Text(
                                  formatSenderInitials(message.sender),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Flexible(
                            flex: 1,
                            fit: FlexFit.tight,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                  color: Colors.lightBlue,
                                  borderRadius: bubbleBorder),
                              child: Flex(
                                  direction: Axis.vertical,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          formatSender(message.sender),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      margin: EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        message.body,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: textColor,
                                          fontWeight: FontWeight.w100,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      formatTimestamp(
                                        lastUpdateMillis: message.timestamp,
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textColor,
                                      ),
                                    ),
                                  ]),
                            ),
                          ),
                        ]),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, Store<AppState>>(
        converter: (Store<AppState> store) => store,
        builder: (context, store) {
          final MessageArguments arguments =
              ModalRoute.of(context).settings.arguments;

          double width = MediaQuery.of(context).size.width;
          double messageInputWidth = width - 64;

          final isEditing = inputFieldNode.hasFocus;
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
                PopupMenuButton<Overflow>(
                  icon: Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (Overflow result) {
                    switch (result) {
                      default:
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<Overflow>>[
                    const PopupMenuItem<Overflow>(
                      value: Overflow.search,
                      child: Text('Search'),
                    ),
                    const PopupMenuItem<Overflow>(
                      value: Overflow.allMedia,
                      child: Text('All Media'),
                    ),
                    const PopupMenuItem<Overflow>(
                      value: Overflow.chatSettings,
                      child: Text('Chat Settings'),
                    ),
                    const PopupMenuItem<Overflow>(
                      value: Overflow.inviteFriends,
                      child: Text('Invite Friends'),
                    ),
                    const PopupMenuItem<Overflow>(
                      value: Overflow.muteNotifications,
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
                  Visibility(
                      visible: store.state.roomStore.loading,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: CircularProgressIndicator(
                          strokeWidth: 4.0,
                          valueColor: new AlwaysStoppedAnimation<Color>(
                            PRIMARY_COLOR,
                          ),
                          value: null,
                        ),
                      )),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () {
                        print('STUB REFRESH');
                      },
                      child: buildMessageList(
                        arguments.roomId,
                        context,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: false
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
                        bottom: isEditing ? 12 : 32,
                        left: 8,
                        right: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: messageInputWidth,
                          ),
                          child: TextField(
                            controller: editorController,
                            onEditingComplete: () {
                              print('they pressed it');
                            },
                            onSubmitted: (text) {
                              store.dispatch(sendMessage(
                                body: text,
                                type: 'm.room.message',
                              ));
                              editorController.clear();
                            },
                            onChanged: (text) {
                              this.setState(() {
                                sendable = text != null && text.isNotEmpty;
                              });
                            },
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            focusNode: inputFieldNode,
                            style: TextStyle(height: 1.5, color: Colors.black),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(ENABLED_GREY),
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
                            onTap: () {
                              store.dispatch(sendMessage(
                                body: editorController.text,
                                type: 'm.room.message',
                              ));
                              editorController.clear();
                            },
                            child: CircleAvatar(
                              backgroundColor: Color(PRIMARY),
                              child: Icon(
                                Icons.send,
                                color: Colors.white,
                              ),
                            ),
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
