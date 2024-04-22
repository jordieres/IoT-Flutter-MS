import Foundation
import MetaWear
import MetaWearCpp

class LedManager{
    static let shared = LedManager()
    
    
    func Led(device: MetaWear, blinkCount: Int, color: String) {
        guard let board = device.board else {
            print("Device setup failed or board not found.")
            return
        }
        
        // Determine the LED color
        var ledColor: MblMwLedColor
        switch color.lowercased() {
        case "green":
            ledColor = MBL_MW_LED_COLOR_GREEN
        case "blue":
            ledColor = MBL_MW_LED_COLOR_BLUE
        case "red":
            ledColor = MBL_MW_LED_COLOR_RED
        default:
            print("Invalid color specified for LED.")
            return
        }
        
        // Initialize the LED pattern
        var pattern = MblMwLedPattern()
        mbl_mw_led_load_preset_pattern(&pattern, MBL_MW_LED_PRESET_BLINK)
        pattern.repeat_count = UInt8(blinkCount)
        
        // Write pattern to the board and play it
        mbl_mw_led_stop_and_clear(board) 
        mbl_mw_led_write_pattern(board, &pattern, ledColor)
        mbl_mw_led_play(board)
    }
    
}

