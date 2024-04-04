import 'package:json_annotation/json_annotation.dart';
import 'package:veepoo_sdk/model/device_status.dart';

/// This allows the `Spo2hData` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'spo2h_data.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable()
class Spo2hData {
  Spo2hData();

  /// Set heart rate value
  /// A fixed device can get the normal heart rate value, other devices cannot get it, the default is 0
  int? rateValue;

  /// Obtain blood oxygen value, the range is [0-99],
  /// [0-79]=blood oxygen is far below the normal value, warn users to pay attention,
  /// [80-89]=low blood oxygen concentration, remind users to pay attention,
  /// [90- 95] = low blood oxygen concentration,
  /// [95-99] = normal blood oxygen
  int? value;

  EDeviceStatus? deviceState;
  bool? checking;
  int? checkingProgress;

  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$Spo2hDataFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory Spo2hData.fromJson(Map<String, dynamic> json) => _$Spo2hDataFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$Spo2hDataToJson`.
  Map<String, dynamic> toJson() => _$Spo2hDataToJson(this);
}
