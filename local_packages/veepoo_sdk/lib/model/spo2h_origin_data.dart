import 'package:json_annotation/json_annotation.dart';

/// This allows the `Spo2hOriginData` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'spo2h_origin_data.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable()
class Spo2hOriginData {
  Spo2hOriginData();

  String? date;
  int? allPackNumner; // don't edit this variable name
  int? currentPackNumber;

  int? heartValue;
  int? sportValue;
  int? oxygenValue;
  int? apneaResult;
  int? isHypoxia;
  int? hypoxiaTime;
  int? hypopnea; // don't edit this variable name
  int? cardiacLoad;
  int? hRVariation;
  int? stepValue;
  int? respirationRate;

  double? calValue;
  double? disValue;
  int? calcType;


  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$Spo2hOriginDataFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory Spo2hOriginData.fromJson(Map<String, dynamic> json) => _$Spo2hOriginDataFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$Spo2hOriginDataToJson`.
  Map<String, dynamic> toJson() => _$Spo2hOriginDataToJson(this);
}
