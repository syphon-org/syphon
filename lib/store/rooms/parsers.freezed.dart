// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies

part of 'parsers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
class _$SyncPayloadTearOff {
  const _$SyncPayloadTearOff();

// ignore: unused_element
  _SyncPayload call(
      {Room room,
      List<Event> state,
      List<Reaction> reactions,
      List<Redaction> redactions,
      List<Message> messages,
      Map<String, ReadReceipt> readReceipts,
      Map<String, User> users}) {
    return _SyncPayload(
      room: room,
      state: state,
      reactions: reactions,
      redactions: redactions,
      messages: messages,
      readReceipts: readReceipts,
      users: users,
    );
  }
}

/// @nodoc
// ignore: unused_element
const $SyncPayload = _$SyncPayloadTearOff();

/// @nodoc
mixin _$SyncPayload {
  Room get room;
  List<Event> get state;
  List<Reaction> get reactions;
  List<Redaction> get redactions;
  List<Message> get messages;
  Map<String, ReadReceipt> get readReceipts;
  Map<String, User> get users;

  @JsonKey(ignore: true)
  $SyncPayloadCopyWith<SyncPayload> get copyWith;
}

/// @nodoc
abstract class $SyncPayloadCopyWith<$Res> {
  factory $SyncPayloadCopyWith(
          SyncPayload value, $Res Function(SyncPayload) then) =
      _$SyncPayloadCopyWithImpl<$Res>;
  $Res call(
      {Room room,
      List<Event> state,
      List<Reaction> reactions,
      List<Redaction> redactions,
      List<Message> messages,
      Map<String, ReadReceipt> readReceipts,
      Map<String, User> users});
}

/// @nodoc
class _$SyncPayloadCopyWithImpl<$Res> implements $SyncPayloadCopyWith<$Res> {
  _$SyncPayloadCopyWithImpl(this._value, this._then);

  final SyncPayload _value;
  // ignore: unused_field
  final $Res Function(SyncPayload) _then;

  @override
  $Res call({
    Object room = freezed,
    Object state = freezed,
    Object reactions = freezed,
    Object redactions = freezed,
    Object messages = freezed,
    Object readReceipts = freezed,
    Object users = freezed,
  }) {
    return _then(_value.copyWith(
      room: room == freezed ? _value.room : room as Room,
      state: state == freezed ? _value.state : state as List<Event>,
      reactions:
          reactions == freezed ? _value.reactions : reactions as List<Reaction>,
      redactions: redactions == freezed
          ? _value.redactions
          : redactions as List<Redaction>,
      messages:
          messages == freezed ? _value.messages : messages as List<Message>,
      readReceipts: readReceipts == freezed
          ? _value.readReceipts
          : readReceipts as Map<String, ReadReceipt>,
      users: users == freezed ? _value.users : users as Map<String, User>,
    ));
  }
}

/// @nodoc
abstract class _$SyncPayloadCopyWith<$Res>
    implements $SyncPayloadCopyWith<$Res> {
  factory _$SyncPayloadCopyWith(
          _SyncPayload value, $Res Function(_SyncPayload) then) =
      __$SyncPayloadCopyWithImpl<$Res>;
  @override
  $Res call(
      {Room room,
      List<Event> state,
      List<Reaction> reactions,
      List<Redaction> redactions,
      List<Message> messages,
      Map<String, ReadReceipt> readReceipts,
      Map<String, User> users});
}

/// @nodoc
class __$SyncPayloadCopyWithImpl<$Res> extends _$SyncPayloadCopyWithImpl<$Res>
    implements _$SyncPayloadCopyWith<$Res> {
  __$SyncPayloadCopyWithImpl(
      _SyncPayload _value, $Res Function(_SyncPayload) _then)
      : super(_value, (v) => _then(v as _SyncPayload));

  @override
  _SyncPayload get _value => super._value as _SyncPayload;

  @override
  $Res call({
    Object room = freezed,
    Object state = freezed,
    Object reactions = freezed,
    Object redactions = freezed,
    Object messages = freezed,
    Object readReceipts = freezed,
    Object users = freezed,
  }) {
    return _then(_SyncPayload(
      room: room == freezed ? _value.room : room as Room,
      state: state == freezed ? _value.state : state as List<Event>,
      reactions:
          reactions == freezed ? _value.reactions : reactions as List<Reaction>,
      redactions: redactions == freezed
          ? _value.redactions
          : redactions as List<Redaction>,
      messages:
          messages == freezed ? _value.messages : messages as List<Message>,
      readReceipts: readReceipts == freezed
          ? _value.readReceipts
          : readReceipts as Map<String, ReadReceipt>,
      users: users == freezed ? _value.users : users as Map<String, User>,
    ));
  }
}

/// @nodoc
class _$_SyncPayload implements _SyncPayload {
  _$_SyncPayload(
      {this.room,
      this.state,
      this.reactions,
      this.redactions,
      this.messages,
      this.readReceipts,
      this.users});

  @override
  final Room room;
  @override
  final List<Event> state;
  @override
  final List<Reaction> reactions;
  @override
  final List<Redaction> redactions;
  @override
  final List<Message> messages;
  @override
  final Map<String, ReadReceipt> readReceipts;
  @override
  final Map<String, User> users;

  @override
  String toString() {
    return 'SyncPayload(room: $room, state: $state, reactions: $reactions, redactions: $redactions, messages: $messages, readReceipts: $readReceipts, users: $users)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _SyncPayload &&
            (identical(other.room, room) ||
                const DeepCollectionEquality().equals(other.room, room)) &&
            (identical(other.state, state) ||
                const DeepCollectionEquality().equals(other.state, state)) &&
            (identical(other.reactions, reactions) ||
                const DeepCollectionEquality()
                    .equals(other.reactions, reactions)) &&
            (identical(other.redactions, redactions) ||
                const DeepCollectionEquality()
                    .equals(other.redactions, redactions)) &&
            (identical(other.messages, messages) ||
                const DeepCollectionEquality()
                    .equals(other.messages, messages)) &&
            (identical(other.readReceipts, readReceipts) ||
                const DeepCollectionEquality()
                    .equals(other.readReceipts, readReceipts)) &&
            (identical(other.users, users) ||
                const DeepCollectionEquality().equals(other.users, users)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(room) ^
      const DeepCollectionEquality().hash(state) ^
      const DeepCollectionEquality().hash(reactions) ^
      const DeepCollectionEquality().hash(redactions) ^
      const DeepCollectionEquality().hash(messages) ^
      const DeepCollectionEquality().hash(readReceipts) ^
      const DeepCollectionEquality().hash(users);

  @JsonKey(ignore: true)
  @override
  _$SyncPayloadCopyWith<_SyncPayload> get copyWith =>
      __$SyncPayloadCopyWithImpl<_SyncPayload>(this, _$identity);
}

abstract class _SyncPayload implements SyncPayload {
  factory _SyncPayload(
      {Room room,
      List<Event> state,
      List<Reaction> reactions,
      List<Redaction> redactions,
      List<Message> messages,
      Map<String, ReadReceipt> readReceipts,
      Map<String, User> users}) = _$_SyncPayload;

  @override
  Room get room;
  @override
  List<Event> get state;
  @override
  List<Reaction> get reactions;
  @override
  List<Redaction> get redactions;
  @override
  List<Message> get messages;
  @override
  Map<String, ReadReceipt> get readReceipts;
  @override
  Map<String, User> get users;
  @override
  @JsonKey(ignore: true)
  _$SyncPayloadCopyWith<_SyncPayload> get copyWith;
}
