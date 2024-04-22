import UIKit

class ToastManager {
    static let shared = ToastManager() 

    private init() {}

    func showToast(message: String, duration: TimeInterval = 2.0, in viewController: UIViewController?) {
        guard let viewController = viewController else {
            return
        }
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        viewController.present(alert, animated: true, completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                alert.dismiss(animated: true, completion: nil)
            }
        })
    }
}
