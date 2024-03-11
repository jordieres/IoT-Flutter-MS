import 'package:json_annotation/json_annotation.dart';

/// This allows the `SleepData` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'sleep_data.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable()
class SleepData {
  SleepData();

  String? date;

  /// Get sleep quality [1-5] level, the higher the level, the better the sleep quality
  int? sleepQulity;

  /// Number of times to get up during sleep
  int? wakeCount;
  /// Light sleep duration
  int? lowSleepTime;
  /// Total sleep time
  int? allSleepTime;

  /// Get the sleep curve, which is mainly used for a more visualized UI to display the sleep state
  /// (refer to our APP, 360 application market search Hband).
  /// If your sleep interface has no special requirements for the UI, you can ignore it.
  /// The sleep curve is divided into normal sleep and Accurate sleep,
  /// normal sleep is a set of strings consisting of 0, 1, and 2, each character represents a duration of 5 minutes,
  /// where 0 means light sleep, 1 means deep sleep, and 2 means wake up, such as "201112", the length is 6.
  /// It means that the sleep stage is 30 minutes in total, the head and the tail are awakened for 5 minutes,
  /// the light sleep is 5 minutes in the middle, and the deep sleep is 15 minutes; if it is a precise sleep,
  /// the sleep curve is a set of strings composed of 0,1,2,3,4 , Each character represents the duration of 1 minute,
  /// where 0 means deep sleep, 1 means light sleep, 2 means rapid eye movement, 3 means insomnia, and 4 means wake up.
  String? sleepLine;
  /// Get time to fall asleep
  DateTime? sleepDown;
  /// Get wake up time
  DateTime? sleepUp;

  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$SleepDataFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory SleepData.fromJson(Map<String, dynamic> json) => _$SleepDataFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$SleepDataToJson`.
  Map<String, dynamic> toJson() => _$SleepDataToJson(this);
}
