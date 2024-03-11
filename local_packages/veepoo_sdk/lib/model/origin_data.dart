import 'package:json_annotation/json_annotation.dart';

/// This allows the `OriginData` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'origin_data.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable()
class OriginData {
  OriginData();

  String? date;

  int? allPackage;
  int? packageNumber;
  int? rateValue; // Get heart rate value, range [30-200]
  int? sportValue; // Get exercise amount value [0-65536], the greater the value, the more intense the exercise, which is divided into 5 levels, namely [0-220], [201-700], [701-1400], [1401-3200], [3201-65536]
  int? stepValue; // Get step count
  int? highValue;
  int? lowValue;
  int? wear;

  double? calValue;
  double? disValue;
  int? calcType;


  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$OriginDataFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory OriginData.fromJson(Map<String, dynamic> json) => _$OriginDataFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$OriginDataToJson`.
  Map<String, dynamic> toJson() => _$OriginDataToJson(this);
}
