import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

enum SortOrder {
  Custom,
  Latest,
  Oldest,
  Alphabetical,
}

@JsonSerializable()
class ChatList extends Equatable {
  final String id;
  final String emoji;
  // List<roomId>
  final List<String> roomIds;
  // order is used only under the "Custom" sort order
  // Map<order, roomId>
  final Map<int, String> order;

  const ChatList({
    required this.id,
    this.emoji = '',
    this.order = const {},
    this.roomIds = const [],
  });

  @override
  List<Object?> get props => [
        id,
        emoji,
        order,
        roomIds,
      ];

  Map<String, dynamic> toJson() => _$ChatListToJson(this);

  factory ChatList.fromJson(Map<String, dynamic> json) => _$ChatListFromJson(json);
}
