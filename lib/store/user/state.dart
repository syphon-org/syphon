// Package imports:
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

// Project imports:
import 'package:syphon/global/libs/hive/type-ids.dart';
import 'package:syphon/store/user/model.dart';

part 'state.g.dart';

@HiveType(typeId: UsersStoreHiveId)
class UsersStore extends Equatable {
  @HiveField(0)
  final Map<String, User> users;

  final bool loading;

  const UsersStore({
    this.users = const {},
    this.loading = false,
  });

  UsersStore copyWith({
    Map<String, User> users,
    bool loading,
  }) {
    return UsersStore(
      users: users ?? this.users,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object> get props => [
        users,
        loading,
      ];
}
