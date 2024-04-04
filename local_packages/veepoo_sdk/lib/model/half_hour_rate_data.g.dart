// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'half_hour_rate_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HalfHourRateData _$HalfHourRateDataFromJson(Map<String, dynamic> json) =>
    HalfHourRateData()
      ..date = json['date'] as String?
      ..time =
          json['time'] == null ? null : DateTime.parse(json['time'] as String)
      ..rateValue = json['rateValue'] as int?
      ..ecgCount = json['ecgCount'] as int?
      ..ppgCount = json['ppgCount'] as int?;

Map<String, dynamic> _$HalfHourRateDataToJson(HalfHourRateData instance) =>
    <String, dynamic>{
      'date': instance.date,
      'time': instance.time?.toIso8601String(),
      'rateValue': instance.rateValue,
      'ecgCount': instance.ecgCount,
      'ppgCount': instance.ppgCount,
    };
