import 'package:json_annotation/json_annotation.dart';

/// This allows the `HrData` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'hr_data.g.dart';

enum EHeartStatus {
  STATE_HEART_BUSY, // Device is busy
  STATE_HEART_DETECT, // Device is detecting
  STATE_HEART_NORMAL, // checking
  STATE_HEART_WEAR_ERROR, // Testing, but wearing wrong
  STATE_INIT, // Initialization
}

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable()
class HrData {
  HrData();

  EHeartStatus? heartStatus;
  int? data; /// Set the heart rate value, range [20-300]

  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$HrDataFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory HrData.fromJson(Map<String, dynamic> json) => _$HrDataFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$HrDataToJson`.
  Map<String, dynamic> toJson() => _$HrDataToJson(this);
}
