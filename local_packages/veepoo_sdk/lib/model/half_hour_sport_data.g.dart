// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'half_hour_sport_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HalfHourSportData _$HalfHourSportDataFromJson(Map<String, dynamic> json) =>
    HalfHourSportData()
      ..date = json['date'] as String?
      ..time =
          json['time'] == null ? null : DateTime.parse(json['time'] as String)
      ..stepValue = json['stepValue'] as int?
      ..sportValue = json['sportValue'] as int?
      ..disValue = (json['disValue'] as num?)?.toDouble()
      ..calValue = (json['calValue'] as num?)?.toDouble();

Map<String, dynamic> _$HalfHourSportDataToJson(HalfHourSportData instance) =>
    <String, dynamic>{
      'date': instance.date,
      'time': instance.time?.toIso8601String(),
      'stepValue': instance.stepValue,
      'sportValue': instance.sportValue,
      'disValue': instance.disValue,
      'calValue': instance.calValue,
    };
