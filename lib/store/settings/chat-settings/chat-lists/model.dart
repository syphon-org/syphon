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
  final String name;
  final String symbol; // emoji for now
  // List<roomId>
  final List<String> roomIds;
  // order is used only under the "Custom" sort order
  // Map<order, roomId>
  final Map<int, String> order;

  final int position; // global position in home list

  const ChatList({
    required this.id,
    this.name = 'New List',
    this.symbol = '',
    this.order = const {},
    this.roomIds = const [],
    this.position = 0,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        symbol,
        order,
        roomIds,
        position,
      ];

  Map<String, dynamic> toJson() => _$ChatListToJson(this);

  factory ChatList.fromJson(Map<String, dynamic> json) => _$ChatListFromJson(json);
}
