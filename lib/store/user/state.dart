// Package imports:
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

// Project imports:
import 'package:syphon/global/libs/hive/type-ids.dart';
import 'package:syphon/store/user/model.dart';

part 'state.g.dart';

@HiveType(typeId: UserStoreHiveId)
class UserStore extends Equatable {
  final bool loading;

  @HiveField(0)
  final Map<String, User> users;

  @HiveField(1)
  final List<User> invites;

  const UserStore({
    this.users = const {},
    this.invites = const [],
    this.loading = false,
  });

  UserStore copyWith({
    bool loading,
    List<User> invites,
    Map<String, User> users,
  }) {
    return UserStore(
      users: users ?? this.users,
      invites: invites ?? this.invites,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object> get props => [
        users,
        invites,
        loading,
      ];
}
