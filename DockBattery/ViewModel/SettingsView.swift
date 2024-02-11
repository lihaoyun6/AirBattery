//
//  SettingsView.swift
//  DockBattery
//
//  Created by apple on 2023/9/7.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("appearance") var appearance = "auto"
    @AppStorage("dockTheme") var dockTheme = "battery"
    @AppStorage("weatherMode") var weatherMode = "off"
    @AppStorage("timeLeft") var timeLeft = "false"
    @AppStorage("showThisMac") var showThisMac = "icon"
    @AppStorage("multiInfoMainBattery") var multiInfoMainBattery:String = "@MacInternalBattery"
    @ObservedObject var locationManager = LocationManagerSingleton.shared
    @State var devices:[String] = []
    
    var location: String { locationManager.locationName }
    var city: String { locationManager.locationCity }
    
    var body: some View {
        VStack{
            Text("Location: ".local + (city != "" ? city : location))
                .foregroundColor(.gray)
                .font(.system(size: 8, weight: .medium))
                .offset(y:12)
            ZStack{
                RoundedRectangle(cornerRadius: 8.0)
                //.stroke(lineWidth: 1)
                    .fill(.gray)
                    .opacity(0.05)
                    .frame(width: 170, height: 110)
                RoundedRectangle(cornerRadius: 8.0)
                    .stroke(lineWidth: 1)
                    .fill(.gray)
                    .opacity(0.15)
                    .frame(width: 170, height: 110)
                VStack{
                    Text("Display Mode")
                        .font(.system(size: 20, weight: .medium))
                        .offset(y: 2)
                    HStack(spacing: 19){
                        VStack(spacing: 0){
                            MultiBatteryView()
                                .opacity(dockTheme == "battery" ? 1.0 : 0.3)
                                .onTapGesture { dockTheme = "battery" }
                            Text("Battery")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(dockTheme == "battery" ? .blue : .gray)
                                .frame(width: 110)
                        }
                        Divider()
                            .frame(height: 150)
                            .offset(y:4)
                        VStack(spacing: 0){
                            MultiInfoView(fromDock: false)
                                .opacity(dockTheme == "multinfo" ? 1.0 : 0.3)
                                .onTapGesture { dockTheme = "multinfo" }
                            Text("Dashboard")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(dockTheme == "battery" ? .gray : .blue)
                                .frame(width: 110)
                        }
                    }
                    .offset(y:-4)
                }
                .scaleEffect(0.5)
                .frame(width: 230, height: 110)
            }.padding(.top)
            VStack(spacing: 10){
                Text("Appearance")
                    .font(.system(size: 10, weight: .medium))
                Picker("", selection: $appearance) {
                    Text("Automatic").tag("auto")
                    Text("Light").tag("false")
                    Text("Dark").tag("true")
                }
                .font(.system(size: 10, weight: .medium))
                .pickerStyle(.radioGroup)
                .horizontalRadioGroupLayout()
                if dockTheme == "multinfo" {
                    Text("Weather")
                        .font(.system(size: 10, weight: .medium))
                    Picker("", selection: $weatherMode) {
                        Text("Hidden").tag("off")
                        Text("Use °C").tag("c")
                        Text("Use °F").tag("f")
                    }
                    .font(.system(size: 10, weight: .medium))
                    .pickerStyle(.radioGroup)
                    .horizontalRadioGroupLayout()
                    Text("Battery on Dock")
                        .font(.system(size: 10, weight: .medium))
                    Picker("", selection: $multiInfoMainBattery) {
                        Text("This Mac").tag("@MacInternalBattery")
                        ForEach(devices.indices, id: \.self) { index in
                            Text(devices[index]).tag(devices[index])
                        }
                    }
                    .frame(width: 180)
                    .font(.system(size: 10, weight: .medium))
                    .pickerStyle(MenuPickerStyle())
                    //.horizontalRadioGroupLayout()
                } else if dockTheme == "battery" {
                    Text("Show This Mac")
                        .font(.system(size: 10, weight: .medium))
                    Picker("", selection: $showThisMac) {
                        Text("Icon").tag("icon")
                        Text("Percent").tag("percent")
                        Text("Hidden").tag("hidden")
                    }
                    .font(.system(size: 10, weight: .medium))
                    .pickerStyle(.radioGroup)
                    .horizontalRadioGroupLayout()
                }
            }
            .padding(.bottom)
            .frame(width: 230, height: 170)
        }
        .onAppear{ devices = AirBatteryModel.getAllName() }
        .onReceive(themeTimer) { _ in devices = AirBatteryModel.getAllName() }
    }
}
