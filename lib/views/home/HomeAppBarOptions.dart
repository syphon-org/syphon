import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/domain/rooms/actions.dart';
import 'package:syphon/domain/rooms/room/model.dart';
import 'package:syphon/global/colors.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/libraries/redux/hooks.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/views/home/chat/chat-detail-screen.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/widgets/dialogs/dialog-confirm.dart';

class AppBarHomeOptions extends HookWidget implements PreferredSizeWidget {
  const AppBarHomeOptions({
    super.key,
    this.selectedChatsIds = const [],
    this.onSelectAll,
    this.onToggleChatOptions,
    this.onDismissChatOptions,
  });

  final List<String> selectedChatsIds;

  final Function? onSelectAll;
  final Function? onToggleChatOptions;
  final Function? onDismissChatOptions;

  @override
  Size get preferredSize => AppBar().preferredSize;

  @override
  Widget build(BuildContext context) {
    final dispatch = useDispatch<AppState>();

    final rooms = useSelectorUnsafe<AppState, Map<String, Room>>(
          (state) => state.roomStore.rooms,
        ) ??
        {};

    final selectedChats = useMemoized(
      () => Map.fromIterable(
        selectedChatsIds,
        key: (id) => id,
        value: (id) => rooms[id] ?? Room(id: id),
      ),
      [selectedChatsIds],
    );

    final isAllDirect = useMemoized(
      () => selectedChats.values.every((chat) => chat.direct),
      [selectedChatsIds],
    );

    onArchiveChats() async {
      showDialog(
        context: context,
        builder: (dialogContext) => DialogConfirm(
          title: Strings.buttonArchiveChat.capitalize(),
          content: Strings.confirmArchiveRooms(rooms: selectedChats.values),
          confirmStyle: const TextStyle(color: Colors.red),
          confirmText: Strings.buttonConfirmFormal.capitalize(),
          onDismiss: () => Navigator.pop(dialogContext),
          onConfirm: () async {
            try {
              await Future.forEach(selectedChats.values, (Room room) async {
                await dispatch(archiveRoom(room: room));
              });

              onDismissChatOptions?.call();
            } catch (error) {
              console.error(error.toString());
            }

            Navigator.of(dialogContext).pop();
          },
        ),
      );
    }

    onLeaveChats() async {
      showDialog(
        context: context,
        builder: (dialogContext) => DialogConfirm(
          title: Strings.buttonLeaveChat.capitalize(),
          content: Strings.confirmLeaveRooms(rooms: selectedChats.values),
          confirmStyle: const TextStyle(color: Colors.red),
          confirmText: Strings.buttonConfirmFormal.capitalize(),
          onDismiss: () => Navigator.pop(dialogContext),
          onConfirm: () async {
            try {
              final selectedChats0 = Map<String, Room>.from(selectedChats);

              await Future.forEach<Room>(selectedChats0.values, (Room room) async {
                await dispatch(leaveRoom(room: room));
                onToggleChatOptions?.call(room: room);
              });

              onDismissChatOptions?.call();
            } catch (error) {
              console.error(error.toString());
            }

            Navigator.of(dialogContext).pop();
          },
        ),
      );
    }

    onDeleteChats() async {
      showDialog(
        context: context,
        builder: (dialogContext) => DialogConfirm(
          title: Strings.buttonDeleteChat.capitalize(),
          content: Strings.confirmDeleteRooms(rooms: selectedChats.values),
          confirmStyle: const TextStyle(color: Colors.red),
          confirmText: Strings.buttonConfirmFormal.capitalize(),
          onDismiss: () => Navigator.pop(dialogContext),
          onConfirm: () async {
            final selectedChats0 = Map<String, Room>.from(selectedChats);

            await Future.forEach(selectedChats0.values, (Room room) async {
              await dispatch(removeRoom(room: room));
            });

            onDismissChatOptions?.call();
            Navigator.of(dialogContext).pop();
          },
        ),
      );
    }

    return AppBar(
      backgroundColor: const Color(AppColors.greyDefault),
      automaticallyImplyLeading: false,
      titleSpacing: 0.0,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: IconButton(
              icon: const Icon(Icons.close),
              color: Colors.white,
              iconSize: Dimensions.buttonAppBarSize,
              tooltip: Strings.labelClose.capitalize(),
              onPressed: () => onDismissChatOptions?.call(),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        Visibility(
          visible: selectedChats.length == 1,
          child: IconButton(
            icon: const Icon(Icons.info_outline),
            iconSize: Dimensions.buttonAppBarSize,
            tooltip: Strings.buttonRoomDetails.capitalize(),
            color: Colors.white,
            onPressed: () {
              Navigator.pushNamed(
                context,
                Routes.chatSettings,
                arguments: ChatDetailsArguments(
                  roomId: selectedChats.values.first.id,
                  title: selectedChats.values.first.name,
                ),
              );
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.archive_outlined),
          iconSize: Dimensions.buttonAppBarSize,
          tooltip: Strings.buttonArchiveChat.capitalize(),
          color: Colors.white,
          onPressed: () => onArchiveChats(),
        ),
        IconButton(
          icon: const Icon(Icons.exit_to_app),
          iconSize: Dimensions.buttonAppBarSize,
          tooltip: Strings.buttonLeaveChat.capitalize(),
          color: Colors.white,
          onPressed: () => onLeaveChats(),
        ),
        Visibility(
          visible: isAllDirect,
          child: IconButton(
            icon: const Icon(Icons.delete_outline),
            iconSize: Dimensions.buttonAppBarSize,
            tooltip: Strings.buttonDeleteChat.capitalize(),
            color: Colors.white,
            onPressed: () => onDeleteChats(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.select_all),
          iconSize: Dimensions.buttonAppBarSize,
          tooltip: Strings.buttonSelectAll.capitalize(),
          color: Colors.white,
          onPressed: () => onSelectAll?.call(),
        ),
      ],
    );
  }
}
