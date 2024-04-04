// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spo2h_origin_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Spo2hOriginData _$Spo2hOriginDataFromJson(Map<String, dynamic> json) =>
    Spo2hOriginData()
      ..date = json['date'] as String?
      ..allPackNumner = json['allPackNumner'] as int?
      ..currentPackNumber = json['currentPackNumber'] as int?
      ..heartValue = json['heartValue'] as int?
      ..sportValue = json['sportValue'] as int?
      ..oxygenValue = json['oxygenValue'] as int?
      ..apneaResult = json['apneaResult'] as int?
      ..isHypoxia = json['isHypoxia'] as int?
      ..hypoxiaTime = json['hypoxiaTime'] as int?
      ..hypopnea = json['hypopnea'] as int?
      ..cardiacLoad = json['cardiacLoad'] as int?
      ..hRVariation = json['hRVariation'] as int?
      ..stepValue = json['stepValue'] as int?
      ..respirationRate = json['respirationRate'] as int?
      ..calValue = (json['calValue'] as num?)?.toDouble()
      ..disValue = (json['disValue'] as num?)?.toDouble()
      ..calcType = json['calcType'] as int?;

Map<String, dynamic> _$Spo2hOriginDataToJson(Spo2hOriginData instance) =>
    <String, dynamic>{
      'date': instance.date,
      'allPackNumner': instance.allPackNumner,
      'currentPackNumber': instance.currentPackNumber,
      'heartValue': instance.heartValue,
      'sportValue': instance.sportValue,
      'oxygenValue': instance.oxygenValue,
      'apneaResult': instance.apneaResult,
      'isHypoxia': instance.isHypoxia,
      'hypoxiaTime': instance.hypoxiaTime,
      'hypopnea': instance.hypopnea,
      'cardiacLoad': instance.cardiacLoad,
      'hRVariation': instance.hRVariation,
      'stepValue': instance.stepValue,
      'respirationRate': instance.respirationRate,
      'calValue': instance.calValue,
      'disValue': instance.disValue,
      'calcType': instance.calcType,
    };
