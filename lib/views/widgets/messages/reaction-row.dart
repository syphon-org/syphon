import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:syphon/domain/events/reactions/model.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/views/widgets/lifecycle.dart';

class ReactionRow extends StatefulWidget {
  final String currentUserId;
  final List<Reaction> reactions;

  final Function? onToggleReaction;

  const ReactionRow({
    super.key,
    this.reactions = const [],
    this.currentUserId = '',
    this.onToggleReaction,
  });

  @override
  State<ReactionRow> createState() => _ReactionRowState();
}

class _ReactionRowState extends State<ReactionRow> with Lifecycle<ReactionRow> {
  var reactionsMap = <String, int>{};
  var reactionsUserMap = <String, bool>{};

  @override
  void onMounted() {
    super.onMounted();

    final store = StoreProvider.of<AppState>(context);
    final currentUserId = store.state.authStore.currentUser.userId;

    setState(() {
      for (final reaction in widget.reactions) {
        reactionsMap.update(
          reaction.body ?? '',
          (value) => value + 1,
          ifAbsent: () => 1,
        );

        reactionsUserMap.update(
          reaction.body ?? '',
          (value) => value || reaction.sender == currentUserId,
          ifAbsent: () => reaction.sender == currentUserId,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reactionKeys = reactionsMap.keys;
    final reactionCounts = reactionsMap.values;

    return ListView.builder(
      shrinkWrap: true,
      physics: ClampingScrollPhysics(),
      itemCount: reactionKeys.length,
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.antiAlias,
      itemBuilder: (BuildContext context, int index) {
        final reactionKey = reactionKeys.elementAt(index);
        final reactionCount = reactionCounts.elementAt(index);
        final isUserReaction = reactionsUserMap[reactionKey] ?? false;

        return GestureDetector(
          onTap: () => widget.onToggleReaction?.call(reactionKey),
          child: Container(
            width: reactionCount > 1 ? 48 : 32,
            height: 48,
            decoration: BoxDecoration(
              color: isUserReaction
                  ? Theme.of(context).primaryColorDark
                  : Theme.of(context).dialogBackgroundColor,
              borderRadius: BorderRadius.circular(Dimensions.iconSize),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.white,
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  reactionKey,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleMedium!.color,
                    height: 1.35,
                  ),
                ),
                Visibility(
                  visible: reactionCount > 1,
                  child: Container(
                    padding: EdgeInsets.only(left: 3),
                    child: Text(
                      reactionCount.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.titleMedium!.color,
                        height: 1.35,
                      ),
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
}
