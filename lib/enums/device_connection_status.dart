enum DeviceConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  checkingSettings,
  startingStream;

  bool get isConnecting =>
      this == connecting ||
      this == reconnecting ||
      this == checkingSettings ||
      this == startingStream;
}
