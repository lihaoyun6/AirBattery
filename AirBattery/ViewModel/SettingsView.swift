//
//  SettingsView.swift
//  AirBattery
//
//  Created by apple on 2023/9/7.
//

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("showOn") var showOn = "both"
    @AppStorage("appearance") var appearance = "auto"
    @AppStorage("showThisMac") var showThisMac = "icon"
    @AppStorage("rollingMode") var rollingMode = "auto"
    @AppStorage("ideviceOverBLE") var ideviceOverBLE = false
    @AppStorage("cStatusOfBLE") var cStatusOfBLE = false
    @AppStorage("disappearTime") var disappearTime = 20
    @AppStorage("readBTDevice") var readBTDevice = true
    @AppStorage("readBLEDevice") var readBLEDevice = false
    @AppStorage("readIDevice") var readIDevice = true
    @AppStorage("readAirpods") var readAirpods = true
    @AppStorage("intBattOnStatusBar") var intBattOnStatusBar = true
    @AppStorage("statusBarBattPercent") var statusBarBattPercent = false
    @AppStorage("launchAtLogin") var launchAtLogin = false
    
    var body: some View {
        TabView {
            HStack(spacing: 0){
                VStack(alignment:.trailing, spacing: 22){
                    Text("Launch at Login")
                    Text("Show AirBattery on:")
                    Text("Remove Offline Device:")
                }
                VStack(alignment:.leading, spacing: 15){
                    Toggle(isOn: $launchAtLogin) {}
                        .offset(x: 10)
                        .toggleStyle(.switch)
                        .onChange(of: launchAtLogin) { newValue in
                            SMLoginItemSetEnabled("com.lihaoyun6.AirBatteryHelper" as CFString, newValue)
                        }
                    Picker("", selection: $showOn) {
                        Text("Dock").tag("dock")
                        Text("Status Bar").tag("sbar")
                        Text("Both").tag("both")
                    }.pickerStyle(.segmented)
                    
                    Picker("", selection: $disappearTime) {
                        Text("after 20min").tag(20)
                        Text("after 40min").tag(40)
                        Text("Never").tag(92233720368547758)
                    }.pickerStyle(.segmented)
                }.frame(width: 300, alignment: .leading)
            }
            .navigationTitle("AirBattery Settings")
            .tabItem { Label("General", systemImage: "gearshape") }
            
            VStack(spacing: 10){
                /*Text("Data Source:")
                    .font(.system(size: 14, weight: .bold))
                    .offset(y:-2)*/
                HStack{
                    Spacer()
                    VStack(alignment:.trailing, spacing: 15){
                        Toggle(isOn: $readIDevice) {
                            Text("iPhone / iPad / Watch over WiFi")
                        }.toggleStyle(.switch)
                        Toggle(isOn: $ideviceOverBLE) {
                            Text("iPhone / iPad(Cellular) over BT")
                        }.toggleStyle(.switch)
                    }
                    Spacer()
                    VStack(alignment:.leading, spacing: 15){
                        Toggle(isOn: $readAirpods) {
                            Text("AirPods / Beats")
                        }.toggleStyle(.switch)
                        Toggle(isOn: $readBTDevice) {
                            Text("Other BT Device")
                        }.toggleStyle(.switch)
                    }
                    Spacer()
                }
                Divider().frame(width: 440)
                HStack(spacing: 10){
                    Toggle(isOn: $cStatusOfBLE) {
                        Text("Guess charging status of iDevices or BLE devices over BT")
                    }.toggleStyle(.switch)
                }
                HStack(spacing: 10){
                    Toggle(isOn: $readBLEDevice) {
                        Text("Try to get battery info from all BLE devices (Beta)")
                    }.toggleStyle(.switch)
                }
            }
            .navigationTitle("AirBattery Settings")
            .tabItem {
                Image("Nearbility")
                Text("Nearbility")
            }
            
            HStack(spacing: 0){
                VStack(alignment:.trailing, spacing: 22){
                    Text("Appearance:")
                    Text("Show This Mac:")
                    Text("Loop mode:")
                }
                VStack(alignment:.leading, spacing: 15){
                    Picker("", selection: $appearance) {
                        Text("Automatic").tag("auto")
                        Text("Light").tag("false")
                        Text("Dark").tag("true")
                    }.pickerStyle(.segmented)
                    
                    Picker("", selection: $showThisMac) {
                        Text("Icon").tag("icon")
                        Text("Percent").tag("percent")
                        Text("Hidden").tag("hidden")
                    }.pickerStyle(.segmented)
                    
                    Picker("", selection: $rollingMode) {
                        Text("Automatic").tag("auto")
                        Text("On").tag("on")
                        Text("Off").tag("off")
                    }.pickerStyle(.segmented)
                }.frame(width: 300, alignment: .leading)
            }
            .navigationTitle("AirBattery Settings")
            .tabItem {
                Image("dockTile")
                Text("DockTile")
            }
            
            HStack(spacing: 0){
                VStack(alignment:.trailing, spacing: 22){
                    Text("Show Mac Battery:")
                    Text("Show percentage:")
                }.frame(width: 300, alignment: .trailing)
                VStack(alignment:.leading, spacing: 15){
                    HStack{
                        Toggle(isOn: $intBattOnStatusBar) {}.toggleStyle(.switch)
                        Text("(relaunch needed)")
                    }
                    Toggle(isOn: $statusBarBattPercent) {}.toggleStyle(.switch)
                }.frame(width: 300, alignment: .leading)
                    .offset(x: 10)
            }
            .navigationTitle("AirBattery Settings")
            .tabItem { Label("StatusBar", systemImage: "menubar.dock.rectangle") }
        }
        .frame(width: 480, height: 160)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
