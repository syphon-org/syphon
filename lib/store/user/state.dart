import 'package:Tether/global/libs/hive/type-ids.dart';
import 'package:Tether/store/user/model.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'state.g.dart';

@HiveType(typeId: UsersStoreHiveId)
class UsersStore extends Equatable {
  final Map<String, User> users;

  const UsersStore({
    this.users = const {},
  });

  UsersStore copyWith({
    users,
  }) {
    return UsersStore(
      users: users ?? this.users,
    );
  }

  @override
  List<Object> get props => [
        users,
      ];
}
