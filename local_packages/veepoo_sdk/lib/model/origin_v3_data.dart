import 'package:json_annotation/json_annotation.dart';
import 'package:veepoo_sdk/model/hrv_origin_data.dart';
import 'package:veepoo_sdk/model/origin_data.dart';
import 'package:veepoo_sdk/model/spo2h_origin_data.dart';

/// This allows the `OriginV3Data` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'origin_v3_data.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable()
class OriginV3Data {
  OriginV3Data();

  List<OriginData>? originData3s;
  List<HRVOriginData>? hrvOriginData;
  List<Spo2hOriginData>? spo2hOriginData;

  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$OriginV3DataFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory OriginV3Data.fromJson(Map<String, dynamic> json) =>
      _$OriginV3DataFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$OriginV3DataToJson`.
  Map<String, dynamic> toJson() => _$OriginV3DataToJson(this);
}
