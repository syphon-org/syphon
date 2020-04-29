import 'dart:collection';

import 'package:Tether/store/rooms/room/model.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart';

class RoomsConverter implements ICustomConverter<dynamic> {
  const RoomsConverter() : super();

  @override
  dynamic fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) {
    if (jsonValue is LinkedHashMap) {
      print('INTERNAL HASH MAP $jsonValue');
    } else {
      print('UNKNOWN ${jsonValue.runtimeType}');
    }

    return jsonValue as Map<String, Room>;
  }

  // To be done
  @override
  dynamic toJSON(dynamic object, [JsonProperty jsonProperty]) {
    return object;
  }
}
