// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'origin_v3_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OriginV3Data _$OriginV3DataFromJson(Map<String, dynamic> json) => OriginV3Data()
  ..originData3s = (json['originData3s'] as List<dynamic>?)
      ?.map((e) => OriginData.fromJson(e as Map<String, dynamic>))
      .toList()
  ..hrvOriginData = (json['hrvOriginData'] as List<dynamic>?)
      ?.map((e) => HRVOriginData.fromJson(e as Map<String, dynamic>))
      .toList()
  ..spo2hOriginData = (json['spo2hOriginData'] as List<dynamic>?)
      ?.map((e) => Spo2hOriginData.fromJson(e as Map<String, dynamic>))
      .toList();

Map<String, dynamic> _$OriginV3DataToJson(OriginV3Data instance) =>
    <String, dynamic>{
      'originData3s': instance.originData3s,
      'hrvOriginData': instance.hrvOriginData,
      'spo2hOriginData': instance.spo2hOriginData,
    };
