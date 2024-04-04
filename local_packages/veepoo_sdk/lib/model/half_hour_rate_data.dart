import 'package:json_annotation/json_annotation.dart';

/// This allows the `HalfHourRateData` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'half_hour_rate_data.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable()
class HalfHourRateData {
  HalfHourRateData();

  String? date;
  DateTime? time;
  int? rateValue;
  int? ecgCount = 0;
  int? ppgCount = 0;

  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$HalfHourRateDataFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory HalfHourRateData.fromJson(Map<String, dynamic> json) =>
      _$HalfHourRateDataFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$HalfHourRateDataToJson`.
  Map<String, dynamic> toJson() => _$HalfHourRateDataToJson(this);
}
