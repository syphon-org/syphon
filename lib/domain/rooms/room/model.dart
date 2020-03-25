import 'dart:collection';
import 'dart:typed_data';
import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:Tether/domain/rooms/events/model.dart';
import 'package:flutter/foundation.dart';

@jsonSerializable
class Avatar {
  final String uri;
  final String url;
  final String type;
  final Uint8List data;

  const Avatar({
    this.uri,
    this.url,
    this.type,
    this.data,
  });
  Avatar copyWith({
    uri,
    url,
    type,
    data,
  }) {
    return Avatar(
      uri: uri ?? this.uri,
      url: url ?? this.url,
      type: type ?? this.type,
      data: data ?? this.data,
    );
  }

  @override
  String toString() {
    return '{\n' +
        'uri: $uri,\n' +
        'url: $url,\b' +
        'type: $type,\n' +
        'data: $data,\n' +
        '}';
  }
}

@jsonSerializable
class Room {
  final String id;
  final String name;
  final String homeserver;
  final Avatar avatar;
  final String topic;
  final bool direct;
  final bool syncing;
  final String startTime;
  final String endTime;
  final int lastUpdate;

  // Event lists
  final List<Event> state;
  final List<Event> events; // DEPRECATE - every event should never be in store
  final List<Event> messages;
  final List<Message> testing; // this is working

  const Room({
    this.id,
    this.name = 'New Room',
    this.homeserver,
    this.avatar,
    this.topic = '',
    this.direct = false,
    this.syncing = false,
    this.events = const [],
    this.messages = const [],
    this.state = const [],
    this.lastUpdate = 0,
    this.startTime,
    this.endTime,
    this.testing = const [],
  });

  Room copyWith({
    id,
    name,
    homeserver,
    avatar,
    topic,
    lastUpdate,
    direct,
    syncing,
    state,
    events,
    messages,
    startTime,
    endTime,
    testing,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      homeserver: homeserver ?? this.homeserver,
      avatar: avatar ?? this.avatar,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      direct: direct ?? this.direct,
      syncing: syncing ?? this.syncing,
      state: state ?? this.state,
      events: events ?? this.events,
      messages: messages ?? this.messages,
      testing: testing ?? this.testing,
    );
  }

  Room fromMessageEvents(
    List<Event> messageEvents, {
    String startTime,
    String endTime,
  }) {
    int lastUpdate = this.lastUpdate;
    List<Event> existingMessages =
        this.messages.isNotEmpty ? List<Event>.from(this.messages) : [];
    List<Event> messages = messageEvents ?? [];

    // Converting only message events
    final newMessages =
        messages.where((event) => event.type == 'm.room.message').toList();

    // See if the newest message has a greater timestamp
    if (newMessages.isNotEmpty && messages[0].timestamp > lastUpdate) {
      lastUpdate = messages[0].timestamp;
    }

    // Combine current and existing messages on unique ids
    final combinedMessagesMap = HashMap.fromIterable(
      [existingMessages, newMessages].expand((x) => x),
      key: (message) => message.id,
      value: (message) => message,
    );

    final combinedMessages = List<Event>.from(combinedMessagesMap.values);

    // // Should we sort here?
    // combinedMessages.sort((a, b) => b.timestamp - a.timestamp);

    // Add to room
    return this.copyWith(
      messages: combinedMessages,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  // Find details of room based on state events
  // follows spec naming priority and thumbnail downloading
  Room fromStateEvents(
    List<Event> stateEvents, {
    String originDEBUG,
    String username,
    int limit,
  }) {
    String name;
    Avatar avatar;
    String topic;
    int namePriority = 4;
    int lastUpdate = this.lastUpdate;
    List<Event> cachedStateEvents = List<Event>();

    try {
      stateEvents.forEach((event) {
        lastUpdate =
            event.timestamp > lastUpdate ? event.timestamp : lastUpdate;

        switch (event.type) {
          case 'm.room.name':
            namePriority = 1;
            name = event.content['name'];
            break;
          case 'm.room.topic':
            topic = event.content['topic'];
            break;
          case 'm.room.canonical_alias':
            if (namePriority > 2) {
              namePriority = 2;
              name = event.content['alias'];
            }
            break;
          case 'm.room.aliases':
            if (namePriority > 3) {
              namePriority = 3;
              name = event.content['aliases'][0];
            }
            break;
          case 'm.room.avatar':
            final avatarFile = event.content['thumbnail_file'];
            if (avatarFile == null) {
              // Keep previous avatar url until the new uri is fetched
              avatar = this.avatar != null ? this.avatar : Avatar();
              avatar = avatar.copyWith(
                uri: event.content['url'],
              );
            }
            break;
          case 'm.room.member':
            if (this.direct && event.content['displayname'] != username) {
              name = event.content['displayname'];
            }
            break;
          default:
            break;
        }
      });
    } catch (error) {
      print(error);
    } finally {
      // final numberOfEvents = stateEvents != null ? stateEvents.length : 0;
      // print(
      //     '[fromStateEvents] ******** ${originDEBUG} ${this.id} ${numberOfEvents} ******** ');
      // print('[fromStateEvents] name ${name}, ${this.name}');
      // print('[fromStateEvents] avatar ${avatar}, ${this.avatar}');
      // print('[fromStateEvents] topic ${topic}, ${this.topic}');
      // print('[fromStateEvents] last update ${lastUpdate}, ${this.lastUpdate}');
    }

    return this.copyWith(
      name: name ?? this.name ?? 'New Room',
      avatar: avatar ?? this.avatar,
      topic: topic ?? this.topic,
      lastUpdate: lastUpdate > 0 ? lastUpdate : this.lastUpdate,
      state: cachedStateEvents,
    );
  }

  Room fromSync({
    String username,
    Map<String, dynamic> json,
  }) {
    // contains message events
    final List<dynamic> rawTimelineEvents = json['timeline']['events'];
    final List<dynamic> rawStateEvents = json['state']['events'];

    // print(json['summary']);
    // print(json['ephemeral']);
    // Check for message events
    // print('TIMELINE OUTPUT ${json['timeline']}');
    // TODO: final List<dynamic> rawAccountDataEvents = json['account_data']['events'];
    // TODO: final List<dynamic> rawEphemeralEvents = json['ephemeral']['events'];

    final List<Event> stateEvents =
        rawStateEvents.map((event) => Event.fromJson(event)).toList();

    final List<Event> messageEvents =
        rawTimelineEvents.map((event) => Event.fromJson(event)).toList();

    return this
        .fromStateEvents(
          stateEvents,
          username: username,
          originDEBUG: '[fetchSync]',
        )
        .fromMessageEvents(
          messageEvents,
        );
  }

  @override
  String toString() {
    return '{\n' +
        'id: $id,\n' +
        'name: $name,\n' +
        'homeserver: $homeserver,\n' +
        'direct: $direct,\n' +
        'syncing: $syncing,\n' +
        'state: $state,\n' +
        'avatar: $avatar,\n' +
        '}';
  }
}
