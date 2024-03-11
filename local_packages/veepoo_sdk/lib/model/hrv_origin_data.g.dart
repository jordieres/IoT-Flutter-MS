// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hrv_origin_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HRVOriginData _$HRVOriginDataFromJson(Map<String, dynamic> json) =>
    HRVOriginData()
      ..date = json['date'] as String?
      ..allCurrentPackNumber = json['allCurrentPackNumber'] as int?
      ..currentPackNumber = json['currentPackNumber'] as int?
      ..hrvType = json['hrvType'] as int?
      ..hrvValue = json['hrvValue'] as int?
      ..rate = json['rate'] as String?
      ..rrValue =
          (json['rrValue'] as List<dynamic>?)?.map((e) => e as int).toList();

Map<String, dynamic> _$HRVOriginDataToJson(HRVOriginData instance) =>
    <String, dynamic>{
      'date': instance.date,
      'allCurrentPackNumber': instance.allCurrentPackNumber,
      'currentPackNumber': instance.currentPackNumber,
      'hrvType': instance.hrvType,
      'hrvValue': instance.hrvValue,
      'rate': instance.rate,
      'rrValue': instance.rrValue,
    };
