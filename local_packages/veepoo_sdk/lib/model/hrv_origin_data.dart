import 'package:json_annotation/json_annotation.dart';

/// This allows the `HRVOriginData` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'hrv_origin_data.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable()
class HRVOriginData {
  HRVOriginData();

  String? date;
  int? allCurrentPackNumber;
  int? currentPackNumber;

  int? hrvType;
  int? hrvValue;
  String? rate;
  List<int>? rrValue;


  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$HRVOriginDataFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory HRVOriginData.fromJson(Map<String, dynamic> json) => _$HRVOriginDataFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$HRVOriginDataToJson`.
  Map<String, dynamic> toJson() => _$HRVOriginDataToJson(this);
}
