// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bp_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BpData _$BpDataFromJson(Map<String, dynamic> json) => BpData()
  ..status = $enumDecodeNullable(_$EBPDetectStatusEnumMap, json['status'])
  ..progress = json['progress'] as int?
  ..highPressure = json['highPressure'] as int?
  ..lowPressure = json['lowPressure'] as int?
  ..haveProgress = json['haveProgress'] as bool?;

Map<String, dynamic> _$BpDataToJson(BpData instance) => <String, dynamic>{
      'status': _$EBPDetectStatusEnumMap[instance.status],
      'progress': instance.progress,
      'highPressure': instance.highPressure,
      'lowPressure': instance.lowPressure,
      'haveProgress': instance.haveProgress,
    };

const _$EBPDetectStatusEnumMap = {
  EBPDetectStatus.STATE_BP_BUSY: 'STATE_BP_BUSY',
  EBPDetectStatus.STATE_BP_NORMAL: 'STATE_BP_NORMAL',
};
