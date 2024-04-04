// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hr_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HrData _$HrDataFromJson(Map<String, dynamic> json) => HrData()
  ..heartStatus =
      $enumDecodeNullable(_$EHeartStatusEnumMap, json['heartStatus'])
  ..data = json['data'] as int?;

Map<String, dynamic> _$HrDataToJson(HrData instance) => <String, dynamic>{
      'heartStatus': _$EHeartStatusEnumMap[instance.heartStatus],
      'data': instance.data,
    };

const _$EHeartStatusEnumMap = {
  EHeartStatus.STATE_HEART_BUSY: 'STATE_HEART_BUSY',
  EHeartStatus.STATE_HEART_DETECT: 'STATE_HEART_DETECT',
  EHeartStatus.STATE_HEART_NORMAL: 'STATE_HEART_NORMAL',
  EHeartStatus.STATE_HEART_WEAR_ERROR: 'STATE_HEART_WEAR_ERROR',
  EHeartStatus.STATE_INIT: 'STATE_INIT',
};
