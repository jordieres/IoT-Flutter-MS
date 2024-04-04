// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'origin_v0_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OriginV0Data _$OriginV0DataFromJson(Map<String, dynamic> json) => OriginV0Data()
  ..originData = (json['originData'] as List<dynamic>?)
      ?.map((e) => OriginData.fromJson(e as Map<String, dynamic>))
      .toList()
  ..hrvOriginData = (json['hrvOriginData'] as List<dynamic>?)
      ?.map((e) => HRVOriginData.fromJson(e as Map<String, dynamic>))
      .toList();

Map<String, dynamic> _$OriginV0DataToJson(OriginV0Data instance) =>
    <String, dynamic>{
      'originData': instance.originData,
      'hrvOriginData': instance.hrvOriginData,
    };
