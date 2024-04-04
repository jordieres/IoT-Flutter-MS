enum EDeviceStatus {
  BUSY, // Device idle
  CHARG_LOW, // Low power equipment
  CHARGING, // Device is charging
  DETECT_AUTO_FIVE, // The device is busy and is automatically measuring 5 minutes of data
  DETECT_BP, // The device is busy and is measuring blood pressure
  DETECT_FTG, // The equipment is busy and the fatigue is being measured
  DETECT_HEART, // The device is busy and the heart rate is being measured
  DETECT_PPG, // The device is busy and the pulse rate is being measured
  DETECT_SP, // The device is busy and measuring blood oxygen
  FREE, // Device idle
  UNKONW, // unknown
  UNPASS_WEAR, // Device fails to pass
}