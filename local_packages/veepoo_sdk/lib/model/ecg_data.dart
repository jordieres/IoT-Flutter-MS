import 'package:json_annotation/json_annotation.dart';

/// This allows the `EcgDetectResult` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'ecg_data.g.dart';

enum EEcgDetectResultType {
  ALL, // Device manual + device active
  AUTO, // Device active measurement
  MANUALLY, // Device manual measurement
}

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable()
class EcgDetectResult {
  EcgDetectResult();

  int? aveHeart;
  int? aveHrv;
  int? aveQT;
  int? aveResRate;

  int? drawfrequency;
  int? duration;
  int? leadSign;
  List<int>? filterSignals;
  List<int>? originSign;


  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$EcgDetectResultFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory EcgDetectResult.fromJson(Map<String, dynamic> json) => _$EcgDetectResultFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$EcgDetectResultToJson`.
  Map<String, dynamic> toJson() => _$EcgDetectResultToJson(this);
}
