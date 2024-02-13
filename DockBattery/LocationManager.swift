import CoreLocation
//import MapKit

class LocationManagerSingleton: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManagerSingleton()
    private var locationManager = CLLocationManager()
    let geocoder = CLGeocoder()

    @Published var userLocation: String = "-1"
    @Published var locationName: String = ""
    @Published var locationCity: String = ""
    @Published var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined

    override private init() {
        super.init()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationAuthorizationStatus = locationManager.authorizationStatus
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = kCLLocationAccuracyKilometer

        if locationAuthorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        locationManager.startUpdatingLocation()
    }
    
    func getCurrentLocation() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestLocation()
        } else {
            // 处理位置服务未启用的情况
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            userLocation = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
            geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                if let placemark = placemarks?.last {
                    if let name = placemark.name { self.locationName = name }
                    if let city = placemark.locality {
                        self.locationCity = city
                    } else {
                        //if let url = URL(string: "https://api.kertennet.com/geography/locationInfo?lat=\(location.coordinate.latitude)&lng=\(location.coordinate.longitude)") {
                        if let url = URL(string: "https://api.map.baidu.com/geocoder?location=\(location.coordinate.latitude),\(location.coordinate.longitude)&output=json") {
                            fetchData(from: url, maxRetryCount: 2) { result in
                                switch result {
                                case .success(let content):
                                    if let jsonData = content.data(using: .utf8) {
                                        do {
                                            if let JSONObject = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any],
                                                let result = JSONObject["result"] as? [String: Any] {
                                                let city = (result["addressComponent"] as? [String: Any])?["city"] as! String
                                                DispatchQueue.main.async {
                                                    self.locationCity = city
                                                }
                                            }
                                        } catch {
                                            print("JSON error: \(error.localizedDescription)")
                                        }
                                    }
                                case .failure(let error):
                                    print("Error：\(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }
            }
            
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 处理位置获取失败的情况
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationAuthorizationStatus = manager.authorizationStatus
    }
}
