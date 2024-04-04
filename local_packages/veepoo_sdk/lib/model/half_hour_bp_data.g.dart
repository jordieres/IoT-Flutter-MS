// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'half_hour_bp_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HalfHourBpData _$HalfHourBpDataFromJson(Map<String, dynamic> json) =>
    HalfHourBpData()
      ..date = json['date'] as String?
      ..time =
          json['time'] == null ? null : DateTime.parse(json['time'] as String)
      ..highValue = json['highValue'] as int?
      ..lowValue = json['lowValue'] as int?;

Map<String, dynamic> _$HalfHourBpDataToJson(HalfHourBpData instance) =>
    <String, dynamic>{
      'date': instance.date,
      'time': instance.time?.toIso8601String(),
      'highValue': instance.highValue,
      'lowValue': instance.lowValue,
    };
