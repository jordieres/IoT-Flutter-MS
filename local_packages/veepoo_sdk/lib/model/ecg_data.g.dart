// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ecg_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EcgDetectResult _$EcgDetectResultFromJson(Map<String, dynamic> json) =>
    EcgDetectResult()
      ..aveHeart = json['aveHeart'] as int?
      ..aveHrv = json['aveHrv'] as int?
      ..aveQT = json['aveQT'] as int?
      ..aveResRate = json['aveResRate'] as int?
      ..drawfrequency = json['drawfrequency'] as int?
      ..duration = json['duration'] as int?
      ..leadSign = json['leadSign'] as int?
      ..filterSignals = (json['filterSignals'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList()
      ..originSign =
          (json['originSign'] as List<dynamic>?)?.map((e) => e as int).toList();

Map<String, dynamic> _$EcgDetectResultToJson(EcgDetectResult instance) =>
    <String, dynamic>{
      'aveHeart': instance.aveHeart,
      'aveHrv': instance.aveHrv,
      'aveQT': instance.aveQT,
      'aveResRate': instance.aveResRate,
      'drawfrequency': instance.drawfrequency,
      'duration': instance.duration,
      'leadSign': instance.leadSign,
      'filterSignals': instance.filterSignals,
      'originSign': instance.originSign,
    };
