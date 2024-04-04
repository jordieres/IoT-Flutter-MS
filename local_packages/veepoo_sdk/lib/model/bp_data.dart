import 'package:json_annotation/json_annotation.dart';

/// This allows the `BpData` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'bp_data.g.dart';

enum EBPDetectStatus {
  STATE_BP_BUSY, // The device is busy, which means that blood pressure measurement cannot be performed. When receiving this return, please call to end blood pressure measurement
  STATE_BP_NORMAL, // Indicates that blood pressure can be measured
}

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable()
class BpData {
  BpData();

  EBPDetectStatus? status;

  /// Set the measurement progress, range [0-100]
  int? progress;
  /// Get the low pressure value, range [20-200], if it is not in this range, please remind the user that the measurement is invalid
  int? highPressure;
  /// Set the low pressure value, range [20-200], if it is not in this range, please remind the user that the measurement is invalid
  int? lowPressure;
  /// True indicates that the watch has return progress, false indicates that there is no progress, and the watch without progress will return data 55 seconds after starting the measurement
  bool? haveProgress;

  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$BpDataFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory BpData.fromJson(Map<String, dynamic> json) => _$BpDataFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$BpDataToJson`.
  Map<String, dynamic> toJson() => _$BpDataToJson(this);
}
