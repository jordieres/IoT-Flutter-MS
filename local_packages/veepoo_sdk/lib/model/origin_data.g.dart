// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'origin_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OriginData _$OriginDataFromJson(Map<String, dynamic> json) => OriginData()
  ..date = json['date'] as String?
  ..allPackage = json['allPackage'] as int?
  ..packageNumber = json['packageNumber'] as int?
  ..rateValue = json['rateValue'] as int?
  ..sportValue = json['sportValue'] as int?
  ..stepValue = json['stepValue'] as int?
  ..highValue = json['highValue'] as int?
  ..lowValue = json['lowValue'] as int?
  ..wear = json['wear'] as int?
  ..calValue = (json['calValue'] as num?)?.toDouble()
  ..disValue = (json['disValue'] as num?)?.toDouble()
  ..calcType = json['calcType'] as int?;

Map<String, dynamic> _$OriginDataToJson(OriginData instance) =>
    <String, dynamic>{
      'date': instance.date,
      'allPackage': instance.allPackage,
      'packageNumber': instance.packageNumber,
      'rateValue': instance.rateValue,
      'sportValue': instance.sportValue,
      'stepValue': instance.stepValue,
      'highValue': instance.highValue,
      'lowValue': instance.lowValue,
      'wear': instance.wear,
      'calValue': instance.calValue,
      'disValue': instance.disValue,
      'calcType': instance.calcType,
    };
