import Foundation
import MetaWear

//class SensorContext {
//    let handler: MetaWearHandler
//    let hand: String
//
//    init(handler: MetaWearHandler, hand: String) {
//        self.handler = handler
//        self.hand = hand
//    }
//    // Additional methods or logic to manage sensor context
//}

class SensorContext {
    weak var manager: SensorFusionManager?
    var device: MetaWear  // Store the reference to the device

    init(manager: SensorFusionManager, device: MetaWear) {
        self.manager = manager
        self.device = device
    }
}
