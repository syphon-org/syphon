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
  final SortOrder order;
  final List<String> roomIds;

  const ChatList({
    required this.id,
    this.order = SortOrder.Latest, // millis
    this.roomIds = const [],
  });

  @override
  List<Object?> get props => [
        id,
        order,
        roomIds,
      ];

  Map<String, dynamic> toJson() => _$ChatListToJson(this);

  factory ChatList.fromJson(Map<String, dynamic> json) =>
      _$ChatListFromJson(json);
}
