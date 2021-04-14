// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies

part of 'parsers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
class _$EventPayloadTearOff {
  const _$EventPayloadTearOff();

// ignore: unused_element
  _EventPayload call(
      {List<Event> state,
      List<Event> account,
      List<Message> messages,
      List<Reaction> reactions,
      List<Redaction> redactions,
      List<Event> ephemeral}) {
    return _EventPayload(
      state: state,
      account: account,
      messages: messages,
      reactions: reactions,
      redactions: redactions,
      ephemeral: ephemeral,
    );
  }
}

/// @nodoc
// ignore: unused_element
const $EventPayload = _$EventPayloadTearOff();

/// @nodoc
mixin _$EventPayload {
  List<Event> get state;
  List<Event> get account;
  List<Message> get messages;
  List<Reaction> get reactions;
  List<Redaction> get redactions;
  List<Event> get ephemeral;

  @JsonKey(ignore: true)
  $EventPayloadCopyWith<EventPayload> get copyWith;
}

/// @nodoc
abstract class $EventPayloadCopyWith<$Res> {
  factory $EventPayloadCopyWith(
          EventPayload value, $Res Function(EventPayload) then) =
      _$EventPayloadCopyWithImpl<$Res>;
  $Res call(
      {List<Event> state,
      List<Event> account,
      List<Message> messages,
      List<Reaction> reactions,
      List<Redaction> redactions,
      List<Event> ephemeral});
}

/// @nodoc
class _$EventPayloadCopyWithImpl<$Res> implements $EventPayloadCopyWith<$Res> {
  _$EventPayloadCopyWithImpl(this._value, this._then);

  final EventPayload _value;
  // ignore: unused_field
  final $Res Function(EventPayload) _then;

  @override
  $Res call({
    Object state = freezed,
    Object account = freezed,
    Object messages = freezed,
    Object reactions = freezed,
    Object redactions = freezed,
    Object ephemeral = freezed,
  }) {
    return _then(_value.copyWith(
      state: state == freezed ? _value.state : state as List<Event>,
      account: account == freezed ? _value.account : account as List<Event>,
      messages:
          messages == freezed ? _value.messages : messages as List<Message>,
      reactions:
          reactions == freezed ? _value.reactions : reactions as List<Reaction>,
      redactions: redactions == freezed
          ? _value.redactions
          : redactions as List<Redaction>,
      ephemeral:
          ephemeral == freezed ? _value.ephemeral : ephemeral as List<Event>,
    ));
  }
}

/// @nodoc
abstract class _$EventPayloadCopyWith<$Res>
    implements $EventPayloadCopyWith<$Res> {
  factory _$EventPayloadCopyWith(
          _EventPayload value, $Res Function(_EventPayload) then) =
      __$EventPayloadCopyWithImpl<$Res>;
  @override
  $Res call(
      {List<Event> state,
      List<Event> account,
      List<Message> messages,
      List<Reaction> reactions,
      List<Redaction> redactions,
      List<Event> ephemeral});
}

/// @nodoc
class __$EventPayloadCopyWithImpl<$Res> extends _$EventPayloadCopyWithImpl<$Res>
    implements _$EventPayloadCopyWith<$Res> {
  __$EventPayloadCopyWithImpl(
      _EventPayload _value, $Res Function(_EventPayload) _then)
      : super(_value, (v) => _then(v as _EventPayload));

  @override
  _EventPayload get _value => super._value as _EventPayload;

  @override
  $Res call({
    Object state = freezed,
    Object account = freezed,
    Object messages = freezed,
    Object reactions = freezed,
    Object redactions = freezed,
    Object ephemeral = freezed,
  }) {
    return _then(_EventPayload(
      state: state == freezed ? _value.state : state as List<Event>,
      account: account == freezed ? _value.account : account as List<Event>,
      messages:
          messages == freezed ? _value.messages : messages as List<Message>,
      reactions:
          reactions == freezed ? _value.reactions : reactions as List<Reaction>,
      redactions: redactions == freezed
          ? _value.redactions
          : redactions as List<Redaction>,
      ephemeral:
          ephemeral == freezed ? _value.ephemeral : ephemeral as List<Event>,
    ));
  }
}

/// @nodoc
class _$_EventPayload implements _EventPayload {
  _$_EventPayload(
      {this.state,
      this.account,
      this.messages,
      this.reactions,
      this.redactions,
      this.ephemeral});

  @override
  final List<Event> state;
  @override
  final List<Event> account;
  @override
  final List<Message> messages;
  @override
  final List<Reaction> reactions;
  @override
  final List<Redaction> redactions;
  @override
  final List<Event> ephemeral;

  @override
  String toString() {
    return 'EventPayload(state: $state, account: $account, messages: $messages, reactions: $reactions, redactions: $redactions, ephemeral: $ephemeral)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _EventPayload &&
            (identical(other.state, state) ||
                const DeepCollectionEquality().equals(other.state, state)) &&
            (identical(other.account, account) ||
                const DeepCollectionEquality()
                    .equals(other.account, account)) &&
            (identical(other.messages, messages) ||
                const DeepCollectionEquality()
                    .equals(other.messages, messages)) &&
            (identical(other.reactions, reactions) ||
                const DeepCollectionEquality()
                    .equals(other.reactions, reactions)) &&
            (identical(other.redactions, redactions) ||
                const DeepCollectionEquality()
                    .equals(other.redactions, redactions)) &&
            (identical(other.ephemeral, ephemeral) ||
                const DeepCollectionEquality()
                    .equals(other.ephemeral, ephemeral)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(state) ^
      const DeepCollectionEquality().hash(account) ^
      const DeepCollectionEquality().hash(messages) ^
      const DeepCollectionEquality().hash(reactions) ^
      const DeepCollectionEquality().hash(redactions) ^
      const DeepCollectionEquality().hash(ephemeral);

  @JsonKey(ignore: true)
  @override
  _$EventPayloadCopyWith<_EventPayload> get copyWith =>
      __$EventPayloadCopyWithImpl<_EventPayload>(this, _$identity);
}

abstract class _EventPayload implements EventPayload {
  factory _EventPayload(
      {List<Event> state,
      List<Event> account,
      List<Message> messages,
      List<Reaction> reactions,
      List<Redaction> redactions,
      List<Event> ephemeral}) = _$_EventPayload;

  @override
  List<Event> get state;
  @override
  List<Event> get account;
  @override
  List<Message> get messages;
  @override
  List<Reaction> get reactions;
  @override
  List<Redaction> get redactions;
  @override
  List<Event> get ephemeral;
  @override
  @JsonKey(ignore: true)
  _$EventPayloadCopyWith<_EventPayload> get copyWith;
}
