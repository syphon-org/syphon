/**/
Map parseUsers(AppState state) {
  final rooms = state.roomStore.rooms.values as Iterable<Room>;
  final roomsDirect = rooms.where((room) => room.direct);
  final roomsDirectUsers = roomsDirect.map((room) => room.users);

  final allDirectUsers = roomsDirectUsers.fold(
    {},
    (usersAll, users) {
      (usersAll as Map).addAll(users);
      return usersAll;
    },
  );

  return List.from(allDirectUsers.values);
}
