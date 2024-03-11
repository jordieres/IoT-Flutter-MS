// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SleepData _$SleepDataFromJson(Map<String, dynamic> json) => SleepData()
  ..date = json['date'] as String?
  ..sleepQulity = json['sleepQulity'] as int?
  ..wakeCount = json['wakeCount'] as int?
  ..lowSleepTime = json['lowSleepTime'] as int?
  ..allSleepTime = json['allSleepTime'] as int?
  ..sleepLine = json['sleepLine'] as String?
  ..sleepDown = json['sleepDown'] == null
      ? null
      : DateTime.parse(json['sleepDown'] as String)
  ..sleepUp = json['sleepUp'] == null
      ? null
      : DateTime.parse(json['sleepUp'] as String);

Map<String, dynamic> _$SleepDataToJson(SleepData instance) => <String, dynamic>{
      'date': instance.date,
      'sleepQulity': instance.sleepQulity,
      'wakeCount': instance.wakeCount,
      'lowSleepTime': instance.lowSleepTime,
      'allSleepTime': instance.allSleepTime,
      'sleepLine': instance.sleepLine,
      'sleepDown': instance.sleepDown?.toIso8601String(),
      'sleepUp': instance.sleepUp?.toIso8601String(),
    };
