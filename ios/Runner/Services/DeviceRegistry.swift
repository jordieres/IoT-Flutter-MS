class DeviceRegistry {
    static let shared = DeviceRegistry()
    public var devices = [String: DeviceInfo]()  // Key is MAC address
    
    private init() {}
    
    func registerDevice(info: DeviceInfo) {
        devices[info.macAddress] = info
    }
    
    func removeDevice(macAddress: String) {
        devices.removeValue(forKey: macAddress)
    }
    
    func getDeviceInfo(macAddress: String) -> DeviceInfo? {
            return devices[macAddress]
        }
    
    // Maybe a function to get all devices based on type
    func getDevices(byType type: DeviceType) -> [DeviceInfo] {
        return devices.values.filter { $0.type == type }
    }
    
    // Retrieves the hand or foot type along with its orientation (left or right)
    func getDeviceTypeDescriptor(macAddress: String) -> String? {
        guard let deviceInfo = getDeviceInfo(macAddress: macAddress) else {
            return nil
        }
        return "\(deviceInfo.type.rawValue)-DeviceMac:\(deviceInfo.macAddress), \(deviceInfo.type.rawValue)-DeviceName:\(deviceInfo.name)"
    }
}
