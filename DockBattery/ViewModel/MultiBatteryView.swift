//
//  MultiInfoPlusView.swift
//  DockBattery
//
//  Created by apple on 2023/9/8.
//

import SwiftUI

struct MultiBatteryView: View {
    @AppStorage("appearance") var appearance = "auto"
    @AppStorage("showThisMac") var showThisMac = "icon"
    @AppStorage("machineName") var machineName = "Mac"
    @AppStorage("rollingMode") var rollingMode = "off"
    
    @State private var lineWidth = 6.0
    //@State private var started = false
    @State private var darkMode = getDarkMode()
    @State private var ibStatus = getIbByName()
    @State private var batteryList = ["","","",""]
    @State private var battery1 = getIbByID(id: "")
    @State private var battery2 = getIbByID(id: "")
    @State private var battery3 = getIbByID(id: "")
    @State private var battery4 = getIbByID(id: "")
    @State private var lastTime = Date().timeIntervalSince1970
    @State private var rollCount = 1
    
    //@ObservedObject var locationManager = LocationManagerSingleton.shared
    
    //var location: String { locationManager.userLocation }
    //var city: String { locationManager.locationCity }
    
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
                    .trim(from: 0.0, to: CGFloat(min(Double(battery1.batteryLevel)/100.0, 0.5)))
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color(getPowerColor(battery1.batteryLevel)))
                    .rotationEffect(Angle(degrees: 270.0))
                Circle()
                    .trim(from: CGFloat(abs((min(Double(battery1.batteryLevel)/100.0, 1.0))-0.001)), to: CGFloat(abs((min(Double(battery1.batteryLevel)/100.0, 1.0))-0.0005)))
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color(getPowerColor(battery1.batteryLevel)))
                    .shadow(color: .black, radius: lineWidth*0.76, x: 0, y: 0)
                    .rotationEffect(Angle(degrees: 270.0))
                    .clipShape( Circle().stroke(lineWidth: lineWidth) )
                Circle()
                    .trim(from: battery1.batteryLevel > 50 ? 0.25 : 0, to: CGFloat(min(Double(battery1.batteryLevel)/100.0, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color(getPowerColor(battery1.batteryLevel)))
                    .rotationEffect(Angle(degrees: 270.0))
                
                if battery1.hasBattery{
                    if batteryList[0] == "@MacInternalBattery" {
                        if showThisMac == "icon"{
                            Image(nsImage: getMacIcon(machineName)!)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .colorScheme(darkMode ? .dark : .light)
                                .foregroundColor(battery1.isCharging ? Color("dark_green") : (darkMode ? .white : .black))
                                .offset(y:-1)
                                .frame(width: 50, height: 50, alignment: .center)
                                .scaleEffect(0.5)
                        } else {
                            Text(String(battery1.batteryLevel))
                                .colorScheme(darkMode ? .dark : .light)
                                .foregroundColor(battery1.isCharging ? Color("dark_green") : (darkMode ? .white : .black))
                                .font(.custom("Helvetica-Bold", size: battery1.batteryLevel>99 ? 32 : 42))
                                .frame(width: 100, alignment: .center)
                                .scaleEffect(0.5)
                                .offset(x:-0.2, y:1.5)
                        }
                    } else {
                        Image(nsImage: getDeviceIcon(AirBatteryModel.getByID(batteryList[0]) ?? Device(deviceID: "", deviceType: "", deviceName: "", batteryLevel: 0, isCharging: 0, lastUpdate: 0.0))!)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .colorScheme(darkMode ? .dark : .light)
                            .foregroundColor(battery1.isCharging ? Color("dark_green") : (darkMode ? .white : .black))
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
            //.opacity(battery1.hasBattery ? 1.0 : 0.0)
            .frame(width: 38, height: 38, alignment: .center)
            .offset(x:-24, y:-24)
            
            Group {
                Circle()
                    .stroke(lineWidth: lineWidth*1.2)
                    .opacity(darkMode ? 0.2 : 0.13)
                    .foregroundColor(darkMode ? .white : .black)
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(Double(battery2.batteryLevel)/100.0, 0.5)))
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color(getPowerColor(battery2.batteryLevel)))
                    .rotationEffect(Angle(degrees: 270.0))
                Circle()
                    .trim(from: CGFloat(abs((min(Double(battery2.batteryLevel)/100.0, 1.0))-0.001)), to: CGFloat(abs((min(Double(battery2.batteryLevel)/100.0, 1.0))-0.0005)))
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color(getPowerColor(battery2.batteryLevel)))
                    .shadow(color: .black, radius: lineWidth*0.76, x: 0, y: 0)
                    .rotationEffect(Angle(degrees: 270.0))
                    .clipShape( Circle().stroke(lineWidth: lineWidth) )
                Circle()
                    .trim(from: battery2.batteryLevel > 50 ? 0.25 : 0, to: CGFloat(min(Double(battery2.batteryLevel)/100.0, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color(getPowerColor(battery2.batteryLevel)))
                    .rotationEffect(Angle(degrees: 270.0))
                
                if battery2.hasBattery{
                    Image(nsImage: getDeviceIcon(AirBatteryModel.getByID(batteryList[1]) ?? Device(deviceID: "", deviceType: "", deviceName: "", batteryLevel: 0, isCharging: 0, lastUpdate: 0.0))!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .colorScheme(darkMode ? .dark : .light)
                        .foregroundColor(battery2.isCharging ? Color("dark_green") : (darkMode ? .white : .black))
                        .offset(x:0.6, y:0.6)
                        .frame(width: 44, height: 44, alignment: .center)
                        .scaleEffect(0.5)
                }else{
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.custom("Helvetica", size: 36))
                        .foregroundColor(Color("yellow"))
                        .scaleEffect(0.5)
                        .offset(y:-2)
                }
            }
            .opacity(battery2.hasBattery ? 1.0 : 0.0)
            .frame(width: 38, height: 38, alignment: .center)
            .offset(x:24, y:-24)
            
            Group {
                Circle()
                    .stroke(lineWidth: lineWidth*1.2)
                    .opacity(darkMode ? 0.2 : 0.13)
                    .foregroundColor(darkMode ? .white : .black)
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(Double(battery3.batteryLevel)/100.0, 0.5)))
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color(getPowerColor(battery3.batteryLevel)))
                    .rotationEffect(Angle(degrees: 270.0))
                Circle()
                    .trim(from: CGFloat(abs((min(Double(battery3.batteryLevel)/100.0, 1.0))-0.001)), to: CGFloat(abs((min(Double(battery3.batteryLevel)/100.0, 1.0))-0.0005)))
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color(getPowerColor(battery3.batteryLevel)))
                    .shadow(color: .black, radius: lineWidth*0.76, x: 0, y: 0)
                    .rotationEffect(Angle(degrees: 270.0))
                    .clipShape( Circle().stroke(lineWidth: lineWidth) )
                Circle()
                    .trim(from: battery3.batteryLevel > 50 ? 0.25 : 0, to: CGFloat(min(Double(battery3.batteryLevel)/100.0, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color(getPowerColor(battery3.batteryLevel)))
                    .rotationEffect(Angle(degrees: 270.0))
                
                if battery3.hasBattery{
                    Image(nsImage: getDeviceIcon(AirBatteryModel.getByID(batteryList[2]) ?? Device(deviceID: "", deviceType: "", deviceName: "", batteryLevel: 0, isCharging: 0, lastUpdate: 0.0))!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .colorScheme(darkMode ? .dark : .light)
                        .foregroundColor(battery3.isCharging ? Color("dark_green") : (darkMode ? .white : .black))
                        .offset(x:0.6, y:0.6)
                        .frame(width: 44, height: 44, alignment: .center)
                        .scaleEffect(0.5)
                }else{
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.custom("Helvetica", size: 36))
                        .foregroundColor(Color("yellow"))
                        .scaleEffect(0.5)
                        .offset(y:-2)
                }
            }
            .opacity(battery3.hasBattery ? 1.0 : 0.0)
            .frame(width: 38, height: 38, alignment: .center)
            .offset(x:-24, y:24)
            
            Group {
                Circle()
                    .stroke(lineWidth: lineWidth*1.2)
                    .opacity(darkMode ? 0.2 : 0.13)
                    .foregroundColor(darkMode ? .white : .black)
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(Double(battery4.batteryLevel)/100.0, 0.5)))
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color(getPowerColor(battery4.batteryLevel)))
                    .rotationEffect(Angle(degrees: 270.0))
                Circle()
                    .trim(from: CGFloat(abs((min(Double(battery4.batteryLevel)/100.0, 1.0))-0.001)), to: CGFloat(abs((min(Double(battery4.batteryLevel)/100.0, 1.0))-0.0005)))
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color(getPowerColor(battery4.batteryLevel)))
                    .shadow(color: .black, radius: lineWidth*0.76, x: 0, y: 0)
                    .rotationEffect(Angle(degrees: 270.0))
                    .clipShape( Circle().stroke(lineWidth: lineWidth) )
                Circle()
                    .trim(from: battery4.batteryLevel > 50 ? 0.25 : 0, to: CGFloat(min(Double(battery4.batteryLevel)/100.0, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color(getPowerColor(battery4.batteryLevel)))
                    .rotationEffect(Angle(degrees: 270.0))
                
                if battery4.hasBattery{
                    Image(nsImage: getDeviceIcon(AirBatteryModel.getByID(batteryList[3]) ?? Device(deviceID: "", deviceType: "", deviceName: "", batteryLevel: 0, isCharging: 0, lastUpdate: 0.0))!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .colorScheme(darkMode ? .dark : .light)
                        .foregroundColor(battery4.isCharging ? Color("dark_green") : (darkMode ? .white : .black))
                        .offset(x:0.6, y:0.6)
                        .frame(width: 44, height: 44, alignment: .center)
                        .scaleEffect(0.5)
                }else{
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.custom("Helvetica", size: 36))
                        .foregroundColor(Color("yellow"))
                        .scaleEffect(0.5)
                        .offset(y:-2)
                }
            }
            .opacity(battery4.hasBattery ? 1.0 : 0.0)
            .frame(width: 38, height: 38, alignment: .center)
            .offset(x:24, y:24)
        }
        .frame(width: 128, height: 128, alignment: .center)
        .onReceive(themeTimer) { t in
            darkMode = getDarkMode()
            let list = AirBatteryModel.getAllID()
            if rollingMode == "off" { rollCount = 1 }
            let now = Date().timeIntervalSince1970
            var length = 4
            if ibStatus.hasBattery && showThisMac != "hidden" { length = 3 }
            batteryList = sliceList(data: list, length: length, count: rollCount)
            if batteryList == []{
                rollCount = 1
                batteryList = sliceList(data: list, length: length, count: rollCount)
            }
            while batteryList.count < 4 { batteryList.append("") }
            if Double(now) - lastTime >= 20 && rollingMode == "on" {
                lastTime = now
                rollCount = rollCount + 1
            }
            if ibStatus.hasBattery && showThisMac != "hidden" { batteryList.insert("@MacInternalBattery", at: 0) }
            battery1 = getIbByID(id: batteryList[0])
            battery2 = getIbByID(id: batteryList[1])
            battery3 = getIbByID(id: batteryList[2])
            battery4 = getIbByID(id: batteryList[3])
        }
    }
}
