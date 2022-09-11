import 'dart:async';

import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:syphon/global/colors.dart';
import 'package:syphon/global/libs/updater/update-check.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/weburl.dart';
import 'package:syphon/store/hooks.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/search/actions.dart';
import 'package:syphon/store/settings/storage.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';
import 'package:syphon/store/sync/actions.dart';
import 'package:syphon/views/home/chat/chat-screen.dart';
import 'package:syphon/views/home/home-appbar-options.dart';
import 'package:syphon/views/home/home-appbar.dart';
import 'package:syphon/views/home/home-chat-list.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/widgets/appbars/appbar-search.dart';
import 'package:syphon/views/widgets/containers/fabs/fab-bar-expanding.dart';
import 'package:syphon/views/widgets/containers/fabs/fab-ring.dart';
import 'package:syphon/views/widgets/dialogs/dialog-confirm.dart';
import 'package:syphon/views/widgets/loader/index.dart';

class HomeScreen extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final dispatch = useDispatch<AppState>();

    final lastSince = useSelector<AppState, String?>(
      (state) => state.syncStore.lastSince,
    );

    final checkForUpdatesEnabled = useSelector<AppState, bool>(
          (state) => state.settingsStore.checkForUpdatesEnabled,
        ) ??
        false;

    final searchLoading = useSelector<AppState, bool>(
          (state) => state.searchStore.loading,
        ) ??
        false;

    final roomIdsAll = useSelector<AppState, Iterable<String>>(
          (state) => state.roomStore.rooms.keys,
        ) ??
        [];

    final fabType =
        useSelector<AppState, MainFabType>((state) => state.settingsStore.themeSettings.mainFabType) ??
            MainFabType.Ring;

    final fabLabels =
        useSelector<AppState, MainFabLabel>((state) => state.settingsStore.themeSettings.mainFabLabel) ??
            MainFabLabel.Off;

    final fabLocation = useSelector<AppState, MainFabLocation>(
            (state) => state.settingsStore.themeSettings.mainFabLocation) ??
        MainFabLocation.Right;

    final fabKeyRing = useState(GlobalKey<FabCircularMenuState>());

    final onboardingState = useState(false);

    final searchModeState = useState(false);
    final searchTextState = useState('');
    final selectedChatsState = useState<List<String>>([]);

    final onboarding = onboardingState.value;
    final searchMode = searchModeState.value;
    final searchText = searchTextState.value;
    final selectedChats = selectedChatsState.value;

    final searchFocusNode = useFocusNode();

    useEffect(() {
      checkAppUpdate() async {
        // ignore if not enabled
        if (!checkForUpdatesEnabled) return;

        final hasUpdate = await UpdateChecker.checkHasUpdate();

        // ignore if no update is present
        if (!hasUpdate) return;

        await showDialog(
          context: context,
          builder: (dialogContext) => DialogConfirm(
            title: Strings.titleDialogRemoteUpdate.capitalize(),
            content: Strings.contentDialogRemoteUpdate(UpdateChecker.latestVersion),
            confirmStyle: TextStyle(color: Color(AppColors.cyanSyphon)),
            confirmText: Strings.buttonConfirmFormal.capitalize(),
            onDismiss: () async {
              await UpdateChecker.markDismissed(UpdateChecker.latestVersion);
              Navigator.pop(dialogContext);
            },
            onConfirm: () async {
              await UpdateChecker.markUpdated(UpdateChecker.latestVersion);

              try {
                log.info('Download or redirect to APK here'); // TODO:
                await launchUrl(UpdateChecker.latestBuildUri.toString());
              } catch (error) {
                log.error(error.toString());
              }

              Navigator.of(dialogContext).pop();
            },
          ),
        );
      }

      checkTermsTimestamp() async {
        final firstLoginMillis = await loadTermsAgreement();
        final firstLoginTimestamp = DateTime.fromMillisecondsSinceEpoch(firstLoginMillis);
        if (DateTime.now().difference(firstLoginTimestamp).inDays < 1) {
          onboardingState.value = true;
        }
      }

      checkAppUpdate();
      checkTermsTimestamp();
      return null;
    }, []);

    onToggleSearch() {
      searchModeState.value = !searchModeState.value;
      searchTextState.value = '';
    }

    onFetchSync() async {
      await dispatch(fetchSync(since: lastSince));
    }

    onToggleChatOptions({required Room room}) {
      if (searchMode) {
        onToggleSearch();
      }

      if (!selectedChats.contains(room.id)) {
        selectedChatsState.value = List.from(selectedChats..addAll([room.id]));
      } else {
        selectedChatsState.value = List.from(selectedChats..remove(room.id));
      }
    }

    onSearch(String text) {
      searchTextState.value = text;

      if (text.isEmpty) {
        return dispatch(clearSearchResults());
      }

      dispatch(searchMessages(text));
    }

    onDismissChatOptions() {
      selectedChatsState.value = [];
    }

    onSelectChat(Room room, String chatName) {
      if (selectedChats.isNotEmpty) {
        return onToggleChatOptions(room: room);
      }

      Navigator.pushNamed(
        context,
        Routes.chat,
        arguments: ChatScreenArguments(roomId: room.id, title: chatName),
      );

      Timer(Duration(milliseconds: 500), () {
        searchModeState.value = false;
        onDismissChatOptions();
        dispatch(clearSearchResults());
      });
    }

    onSelectAll() {
      if (selectedChats.toSet().containsAll(roomIdsAll)) {
        onDismissChatOptions();
      } else {
        selectedChatsState.value = selectedChats
          ..addAll(roomIdsAll)
          ..toList();
      }
    }

    selectActionAlignment() {
      if (fabLocation == MainFabLocation.Left) {
        return Alignment.bottomLeft;
      }

      return Alignment.bottomRight;
    }

    buildActionFab() {
      if (fabType == MainFabType.Bar) {
        return FabBarExpanding(
          showLabels: onboarding || fabLabels == MainFabLabel.On,
          alignment: selectActionAlignment(),
        );
      }

      return FabRing(
        fabKey: fabKeyRing.value,
        showLabels: onboarding || fabLabels == MainFabLabel.On,
        alignment: selectActionAlignment(),
      );
    }

    selectActionLocation() {
      if (fabLocation == MainFabLocation.Left) {
        return FloatingActionButtonLocation.startFloat;
      }

      return FloatingActionButtonLocation.endFloat;
    }

    Widget currentAppBar = AppBarHome(
      onToggleSearch: () => onToggleSearch(),
    );

    if (searchMode) {
      currentAppBar = AppBarSearch(
        title: Strings.titleSearchUnencrypted,
        label: Strings.labelSearchUnencrypted,
        tooltip: Strings.tooltipSearchUnencrypted,
        forceFocus: true,
        navigate: false,
        startFocused: true,
        focusNode: searchFocusNode,
        onBack: () => onToggleSearch(),
        onToggleSearch: () => onToggleSearch(),
        onSearch: (String text) => onSearch(text),
      );
    }

    if (selectedChats.isNotEmpty) {
      currentAppBar = AppBarHomeOptions(
        selectedChatsIds: selectedChats,
        onSelectAll: () => onSelectAll(),
        onToggleChatOptions: (room) => onToggleChatOptions(room: room),
        onDismissChatOptions: () => onDismissChatOptions(),
      );
    }

    return Scaffold(
      appBar: currentAppBar as PreferredSizeWidget?,
      floatingActionButton: buildActionFab(),
      floatingActionButtonLocation: selectActionLocation(),
      body: Align(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => onFetchSync(),
                child: Stack(
                  children: [
                    Positioned(
                      child: Loader(
                        loading: searchLoading,
                      ),
                    ),
                    GestureDetector(
                      onTap: onDismissChatOptions,
                      child: HomeChatList(
                        searching: searchMode,
                        searchText: searchText,
                        selectedChats: selectedChats,
                        onSelectChat: onSelectChat,
                        onToggleChatOptions: onToggleChatOptions,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
