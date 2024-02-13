//
//  WeatherModel.swift
//  DockBattery
//
//  Created by apple on 2024/2/11.
//

import SwiftUI

struct weatherInfo {
    var weather:String = "🌏"
    var temperatureC:String = "??"
    var temperatureF:String = "??"
}

class WeatherModel {
    static var weather:weatherInfo = weatherInfo()
    static var location:String = "-1"
    static var city:String = ""
    static var lastUpdate:Double = 0
}

class Weathers {
    var scanTimer: Timer?
    //@AppStorage("forceWeather") var forceWeather = false
    @AppStorage("weatherMode") var weatherMode = "off"
    @AppStorage("dockTheme") var dockTheme = "battery"
    
    func startGetting() {
        scanTimer = Timer.scheduledTimer(timeInterval: 660.0, target: self, selector: #selector(updateWeather), userInfo: nil, repeats: true)
        //Thread.detachNewThread {
        //    Thread.sleep(forTimeInterval: 3)
        //    self.updateWeather()
        //}
    }
    
    @objc func updateWeather() { Thread.detachNewThread {
        if self.weatherMode != "off" && self.dockTheme != "battery" {
            self.getWeather()
        }else{
            WeatherModel.weather = weatherInfo()
        }
    } }
    
    func getWeather(){
        Thread.sleep(forTimeInterval: 5)
        var weather = "🌏"
        var temperatureC = "??"
        var temperatureF = "??"
        let now = Date().timeIntervalSince1970
        let locationManager = LocationManagerSingleton.shared
        var location: String { locationManager.userLocation }
        var city: String { locationManager.locationCity }
        
        if location == "-1" { return }
        if location == WeatherModel.location && city == WeatherModel.city && (Double(now) - WeatherModel.lastUpdate) < 600 { return }
        
        //var originalURLString = "https://wttr.in/\(location)?format=1&m"+(forceWeather ? "&nonce=$RANDOM" : "")
        //if city != "" { originalURLString = "https://wttr.in/\(city)?format=1&m"+(forceWeather ? "&nonce=$RANDOM" : "") }
        var originalURLString = "https://wttr.in/\(location)?format=1&m"
        if city != "" { originalURLString = "https://wttr.in/\(city)?format=1&m" }
        
        if let encodedURLString = originalURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            WeatherModel.location = location
            WeatherModel.city = city
            WeatherModel.lastUpdate = now
            if let url = URL(string: encodedURLString) {
                fetchData(from: url, maxRetryCount: 3) { result in
                    switch result {
                    case .success(let content):
                        let dataArray = content.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "C", with: "").replacingOccurrences(of: "+", with: "").replacingOccurrences(of: "°", with: "").replacingOccurrences(of: "🌫", with: "😶‍🌫️").split(separator: " ")
                        if dataArray.count == 2 {
                            if let w = dataArray.first { weather = String(w) }
                            if let t = dataArray.last { temperatureC = String(t); temperatureF = String(lroundf((Float(t) ?? 0.0)*1.82+32)) }
                            WeatherModel.weather = weatherInfo(weather: weather, temperatureC: temperatureC, temperatureF: temperatureF)
                        }else{
                            WeatherModel.weather = weatherInfo()
                        }
                    case .failure(let error):
                        print("Error：\(error.localizedDescription)")
                    }
                }
            }
        }
        //forceWeather = false
    }
}
