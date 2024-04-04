import 'package:json_annotation/json_annotation.dart';
import 'package:veepoo_sdk/model/half_hour_bp_data.dart';
import 'package:veepoo_sdk/model/half_hour_rate_data.dart';
import 'package:veepoo_sdk/model/half_hour_sport_data.dart';

/// This allows the `OriginHalfHourData` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'origin_half_hour_data.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable()
class OriginHalfHourData {
  OriginHalfHourData();

  int? allStep;
  List<HalfHourRateData>? halfHourRateData;
  List<HalfHourBpData>? halfHourBp;
  List<HalfHourSportData>? halfHourSportData;

  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$OriginHalfHourDataFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory OriginHalfHourData.fromJson(Map<String, dynamic> json) =>
      _$OriginHalfHourDataFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$OriginHalfHourDataToJson`.
  Map<String, dynamic> toJson() => _$OriginHalfHourDataToJson(this);
}
