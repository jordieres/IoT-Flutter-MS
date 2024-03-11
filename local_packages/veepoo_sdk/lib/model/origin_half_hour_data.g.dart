// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'origin_half_hour_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OriginHalfHourData _$OriginHalfHourDataFromJson(Map<String, dynamic> json) =>
    OriginHalfHourData()
      ..allStep = json['allStep'] as int?
      ..halfHourRateData = (json['halfHourRateData'] as List<dynamic>?)
          ?.map((e) => HalfHourRateData.fromJson(e as Map<String, dynamic>))
          .toList()
      ..halfHourBp = (json['halfHourBp'] as List<dynamic>?)
          ?.map((e) => HalfHourBpData.fromJson(e as Map<String, dynamic>))
          .toList()
      ..halfHourSportData = (json['halfHourSportData'] as List<dynamic>?)
          ?.map((e) => HalfHourSportData.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$OriginHalfHourDataToJson(OriginHalfHourData instance) =>
    <String, dynamic>{
      'allStep': instance.allStep,
      'halfHourRateData': instance.halfHourRateData,
      'halfHourBp': instance.halfHourBp,
      'halfHourSportData': instance.halfHourSportData,
    };
