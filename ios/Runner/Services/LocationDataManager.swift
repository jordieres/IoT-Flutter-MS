import CoreLocation

class LocationDataManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationDataManager()
    private var locationManager = CLLocationManager()
    
    // Properties to store the last known location
    private var lastKnownLocation: CLLocation?

    
   
    override init() {
                super.init()
        locationManager.delegate = self
               locationManager.requestWhenInUseAuthorization()  //
    }
    
    private func startLocationUpdates() {
        DispatchQueue.main.async {
            self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            self.locationManager.startUpdatingLocation()  // Start continuous location updates
            //TODO: RATE OF UPDATE MUST BE SLOWER LIKE EACH 50 SECONDS
        }
    }


       func fetchLocationAndSaveData(dataType: String, dataBuffer: [String],completion: @escaping (Bool) -> Void) {
           guard let location = self.lastKnownLocation else {
               print("No location data available. Cannot save data.")
               completion(false)

               return
           }
           print("Sending data to FileHandler with location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
           FileHandler.shared.saveDataToFile(dataType: dataType, dataBuffer: dataBuffer, latitude: location.coordinate.latitude, longitude: location.coordinate.longitude,completion: completion)
       }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            startLocationUpdates() // Start updates only when authorized
        case .denied, .restricted:
            print("Location access denied or restricted.")
        default:
            print("Location status not determined.")
        }
    }


       func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
           lastKnownLocation = locations.last
//           print("Updated locations: \(locations)")
       }

       func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
           print("Failed to get location: \(error.localizedDescription)")
       }
    func checkLocationServicesAndNotify() {
        if CLLocationManager.locationServicesEnabled() {
            startLocationUpdates()
        } else {
            // Notify user to enable location services
            DispatchQueue.main.async {
                // Update UI to show a message/alert to enable location services
                print("Location services are disabled. Please enable them in settings.")
            }
        }
    }

    
    }

    
    

