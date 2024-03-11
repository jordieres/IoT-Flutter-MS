import 'package:json_annotation/json_annotation.dart';

/// This allows the `HalfHourSportData` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'half_hour_sport_data.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable()
class HalfHourSportData {
  HalfHourSportData();

  String? date;
  DateTime? time;
  int? stepValue;
  int? sportValue;
  double? disValue;
  double? calValue;

  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$HalfHourSportDataFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory HalfHourSportData.fromJson(Map<String, dynamic> json) =>
      _$HalfHourSportDataFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$HalfHourSportDataToJson`.
  Map<String, dynamic> toJson() => _$HalfHourSportDataToJson(this);
}
