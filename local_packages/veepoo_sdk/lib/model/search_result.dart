import 'package:json_annotation/json_annotation.dart';

/// This allows the `SearchResult` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'search_result.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable()
class SearchResult {
  SearchResult(this.name, this.mac, this.rssi);

  String? name;
  String? mac;
  int? rssi;

  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$SearchResultFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory SearchResult.fromJson(Map<String, dynamic> json) => _$SearchResultFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$SearchResultToJson`.
  Map<String, dynamic> toJson() => _$SearchResultToJson(this);
}
