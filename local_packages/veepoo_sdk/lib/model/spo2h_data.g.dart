// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spo2h_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Spo2hData _$Spo2hDataFromJson(Map<String, dynamic> json) => Spo2hData()
  ..rateValue = json['rateValue'] as int?
  ..value = json['value'] as int?
  ..deviceState =
      $enumDecodeNullable(_$EDeviceStatusEnumMap, json['deviceState'])
  ..checking = json['checking'] as bool?
  ..checkingProgress = json['checkingProgress'] as int?;

Map<String, dynamic> _$Spo2hDataToJson(Spo2hData instance) => <String, dynamic>{
      'rateValue': instance.rateValue,
      'value': instance.value,
      'deviceState': _$EDeviceStatusEnumMap[instance.deviceState],
      'checking': instance.checking,
      'checkingProgress': instance.checkingProgress,
    };

const _$EDeviceStatusEnumMap = {
  EDeviceStatus.BUSY: 'BUSY',
  EDeviceStatus.CHARG_LOW: 'CHARG_LOW',
  EDeviceStatus.CHARGING: 'CHARGING',
  EDeviceStatus.DETECT_AUTO_FIVE: 'DETECT_AUTO_FIVE',
  EDeviceStatus.DETECT_BP: 'DETECT_BP',
  EDeviceStatus.DETECT_FTG: 'DETECT_FTG',
  EDeviceStatus.DETECT_HEART: 'DETECT_HEART',
  EDeviceStatus.DETECT_PPG: 'DETECT_PPG',
  EDeviceStatus.DETECT_SP: 'DETECT_SP',
  EDeviceStatus.FREE: 'FREE',
  EDeviceStatus.UNKONW: 'UNKONW',
  EDeviceStatus.UNPASS_WEAR: 'UNPASS_WEAR',
};
