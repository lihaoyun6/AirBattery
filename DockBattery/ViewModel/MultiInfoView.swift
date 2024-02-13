//
//  MultiInfoView.swift
//  DockBattery
//
//  Created by apple on 2023/9/8.
//

import SwiftUI
import CoreLocation

struct MultiInfoView: View {
    @AppStorage("appearance") var appearance = "auto"
    @AppStorage("weatherMode") var weatherMode = "off"
    @AppStorage("multiInfoMainBattery") var multiInfoMainBattery = "@MacInternalBattery"
    //@AppStorage("forceWeather") var forceWeather = false
    
    @State private var lineWidth = 6.0
    @State private var darkMode = getDarkMode()
    @State private var dateStatus = getDayAndWeek()
    @State private var ibStatus = getPowerState()
    @State private var weatherStatus = WeatherModel.weather
    
    var fromDock = false
    
    var body: some View {
        ZStack {
            Group{
                Image(darkMode ? "background_dark" : "background")
                RoundedRectangle(cornerRadius: 23.5, style: RoundedCornerStyle.continuous)
                    .strokeBorder(darkMode ? .white : .black, lineWidth: 2)
                    .frame(width: 104, height: 104)
                    .opacity(darkMode ? 0.25 : 0.0)
                RoundedRectangle(cornerRadius: 23.5, style: RoundedCornerStyle.continuous)
                    .strokeBorder(.black, lineWidth: 1)
                    .frame(width: 104, height: 104)
                    .opacity(darkMode ? 0.55 : 0.2)
            }
            Group {
                Circle()
                    .stroke(lineWidth: lineWidth*1.2)
                    .opacity(darkMode ? 0.2 : 0.13)
                    .foregroundColor(darkMode ? .white : .black)
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(Double(ibStatus.batteryLevel)/100.0, 0.5)))
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color(getPowerColor(ibStatus.batteryLevel)))
                    .rotationEffect(Angle(degrees: 270.0))
                Circle()
                    .trim(from: CGFloat(abs((min(Double(ibStatus.batteryLevel)/100.0, 1.0))-0.001)), to: CGFloat(abs((min(Double(ibStatus.batteryLevel)/100.0, 1.0))-0.0005)))
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color(getPowerColor(ibStatus.batteryLevel)))
                    .shadow(color: .black, radius: lineWidth*0.76, x: 0, y: 0)
                    .rotationEffect(Angle(degrees: 270.0))
                    .clipShape( Circle().stroke(lineWidth: lineWidth) )
                Circle()
                    .trim(from: ibStatus.batteryLevel > 50 ? 0.25 : 0, to: CGFloat(min(Double(ibStatus.batteryLevel)/100.0, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color(getPowerColor(ibStatus.batteryLevel)))
                    .rotationEffect(Angle(degrees: 270.0))
                
                if ibStatus.hasBattery{
                    if multiInfoMainBattery == "@MacInternalBattery" {
                        Text(String(ibStatus.batteryLevel))
                            .foregroundColor(darkMode ? .white : .black)
                            .font(.custom("Helvetica-Bold", size: ibStatus.batteryLevel>99 ? 32 : 42))
                            .frame(width: 100, alignment: .center)
                            .scaleEffect(0.5)
                            .offset(x:-0.2, y:1.5)
                    } else {
                       Image(nsImage: getDeviceIcon(AirBatteryModel.getByName(multiInfoMainBattery) ?? Device(deviceID: "", deviceType: "", deviceName: "", batteryLevel: 0, isCharging: 0, lastUpdate: 0.0))!)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(darkMode ? .white : .black)
                            .offset(x:0.6, y:0.6)
                            .frame(width: 44, height: 44, alignment: .center)
                            .scaleEffect(0.5)
                    }
                }else{
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.custom("Helvetica", size: 36))
                        .foregroundColor(Color("yellow"))
                        .scaleEffect(0.5)
                        .offset(y:-2)
                }
            }
            .frame(width: 38, height: 38, alignment: .center)
            .offset(x:24, y:-24)
            
            if ibStatus.hasBattery {
                if ibStatus.isCharging {
                    Image(systemName: "bolt.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(darkMode ? .white : .black)
                        .offset(x:1, y:2)
                        .frame(width: 36, height: 36, alignment: .center)
                        .scaleEffect(0.5)
                }else if ibStatus.acPowered {
                    Image("powerplug.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .rotationEffect(Angle(degrees: -90))
                        .foregroundColor(darkMode ? .white : .black)
                        .offset(x:1, y:3)
                        .frame(width: 34, height: 34, alignment: .center)
                        .scaleEffect(0.5)
                }
            }
            
            Group {
                Circle()
                    .opacity(!darkMode ? 0.62 : 0.43)
                    .foregroundColor(!darkMode ? .white : .black)
                    .frame(width: 44, height: 44)
                Circle()
                    .stroke(darkMode ? .white : .black, lineWidth: 1)
                    .frame(width: 45, height: 45)
                    .opacity(0.05)
                Text(dateStatus.week)
                    .fontWeight(.bold)
                    .foregroundColor(Color("red"))
                    .font(.system(size: (dateStatus.locale.contains("zh")) ? 26.5 : 30, weight: .bold))
                    .frame(width: 70, alignment: .center)
                    .scaleEffect(0.5)
                    .offset(x:0.2,y:(dateStatus.locale.contains("zh")) ? -7.7 : -10)
                Text(dateStatus.day)
                    .foregroundColor(darkMode ? .white : .black)
                    .font(.system(size: 38, weight: .medium))
                    .frame(width: 70, alignment: .center)
                    .scaleEffect(0.5)
                    .offset(x:0.2,y:8)
                
            }
            .frame(width: 38, height: 38, alignment: .center)
            .offset(x:-24, y:-24)
            if weatherMode == "off" {
                Text(dateStatus.time)
                    .scaleEffect(0.5)
                    .foregroundColor(darkMode ? .white : .black)
                    .font(.custom("Helvetica-Bold", size: 69))
                    .frame(width: 180, alignment: .center)
                    .offset(y: 30)
            } else {
                Group {
                    Circle()
                        .opacity(darkMode ? 0.9 : 0.0)
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                    let gradient = LinearGradient(gradient: Gradient(colors: [.blue, Color("blue")]), startPoint: .top, endPoint: .bottom)
                    Circle()
                        .fill(gradient)
                        .frame(width: 44, height: 44)
                        .opacity(darkMode ? 0.4 : 1.0)
                        //.frame(width: 44, height: 44)
                    Circle()
                        .stroke(darkMode ? .white : .black, lineWidth: 1)
                        .frame(width: 45, height: 45)
                        .opacity(0.05)
                    Group{
                        Text(weatherStatus.weather)
                            .foregroundColor(.white)
                            .font(.system(size: 43))
                            .scaleEffect(0.5)
                            .offset(y:-9)
                        Text((weatherMode=="f" ? weatherStatus.temperatureF : weatherStatus.temperatureC)+"°")
                            .foregroundColor(.white)
                            .font(.system(size: 35, weight: .bold))
                            .scaleEffect(0.5)
                            .offset(x:(weatherMode=="f" ? weatherStatus.temperatureF : weatherStatus.temperatureC).count<=2 ? 3 : 0.5, y:(weatherMode=="f" ? weatherStatus.temperatureF : weatherStatus.temperatureC).count<=2 ? 9 : 7)
                    }
                    //.offset(y:(weatherMode=="f" ? weatherStatus.temperatureF : weatherStatus.temperatureC) == "??" ? 2 : 0)
                }
                .offset(x:-24, y:23)
                
                VStack(spacing: 0){
                    Text(" "+(dateStatus.time.split(separator: ":").first ?? ""))
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(darkMode ? .white : .black)
                        .font(.custom("Arial-Black", size: 48))
                        .frame(width: 180, alignment: .center)
                    Text(":"+(dateStatus.time.split(separator: ":").last ?? ""))
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(darkMode ? .white : .black)
                        .font(.custom("Arial-Black", size: 48))
                        .frame(width: 180, alignment: .center)
                        .offset(y: -28)
                }
                .offset(x:44, y:60)
                .scaleEffect(0.5)
            }
        }
        .frame(width: 128, height: 128, alignment: .center)
        .onAppear {
            ibStatus = getIbByName(name: multiInfoMainBattery)
            if fromDock { Thread.detachNewThread { Weathers().updateWeather() } }
        }
        .onReceive(themeTimer) { t in
            if fromDock { if CLLocationManager().authorizationStatus != .authorizedAlways { Thread.detachNewThread { Weathers().updateWeather() } } }
            darkMode = getDarkMode()
            dateStatus = getDayAndWeek()
            ibStatus = getIbByName(name: multiInfoMainBattery)
            weatherStatus = WeatherModel.weather
        }
    }
}
