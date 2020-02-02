import 'package:Tether/domain/rooms/selectors.dart';
import 'package:Tether/global/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:Tether/domain/index.dart';
import 'package:redux/redux.dart';

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
          itemBuilder: (BuildContext context, int index) {
            final message = messages[index];
            // if (message.userId != userId) {
            //   return Container(
            // child: Container(
            //   padding: const EdgeInsets.symmetric(
            //     vertical: 16,
            //     horizontal: 24,
            //   ),
            //   child: Text(
            //     message.body,
            //     style: TextStyle(),
            //   ),
            // ),
            //   );
            // }

            return Container(
              child: Flex(
                direction: Axis.vertical,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Card(
                    elevation: 4.0,
                    child: Container(
                      decoration: BoxDecoration(
                        // lighter gradient effect
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.red,
                            Colors.cyan,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    child: Text(
                      message.body,
                      style: TextStyle(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void onSendMessage() {
    print('onSendMessage STUB');
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, AppState>(
        converter: (Store<AppState> store) => store.state,
        builder: (context, state) {
          final MessageArguments arguments =
              ModalRoute.of(context).settings.arguments;

          double width = MediaQuery.of(context).size.width;
          double messageInputWidth = width - 64;
          return Scaffold(
            appBar: AppBar(
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
                      visible: state.roomStore.loading,
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
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: messageInputWidth,
                          ),
                          child: TextField(
                            onEditingComplete: () {
                              print('On Edit complete');
                            },
                            onSubmitted: (testing) {
                              print(testing);
                            },
                            onChanged: (text) {
                              print('$text ${text.split('\n').length}');
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
                                  borderRadius: BorderRadius.circular(24.0)),
                              hintText: 'Tether Message',
                            ),
                          ),
                        ),
                        Container(
                          width: 48.0,
                          child: InkWell(
                            onTap: onSendMessage,
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
