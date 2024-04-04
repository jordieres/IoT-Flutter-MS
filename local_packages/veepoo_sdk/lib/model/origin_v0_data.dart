import 'package:json_annotation/json_annotation.dart';
import 'package:veepoo_sdk/model/hrv_origin_data.dart';
import 'package:veepoo_sdk/model/origin_data.dart';

/// This allows the `OriginV0Data` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'origin_v0_data.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable()
class OriginV0Data {
  OriginV0Data();

  List<OriginData>? originData;
  List<HRVOriginData>? hrvOriginData;

  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$OriginV0DataFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory OriginV0Data.fromJson(Map<String, dynamic> json) =>
      _$OriginV0DataFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$OriginV0DataToJson`.
  Map<String, dynamic> toJson() => _$OriginV0DataToJson(this);
}
