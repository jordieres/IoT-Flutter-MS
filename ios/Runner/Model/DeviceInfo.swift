enum DeviceType: String {
    case handLeft = "LH"
    case handRight = "RH"
    case footLeft = "LF"
    case footRight = "RF"
}

struct DeviceInfo {
    var type: DeviceType
    var macAddress: String
    var name: String
    var side: String
}
