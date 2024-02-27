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
    @AppStorage("showMacOnWidget") var showMacOnWidget = true
    @AppStorage("revListOnWidget") var revListOnWidget = false
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
                        HStack{
                            Toggle(isOn: $readIDevice) {}.toggleStyle(.switch)
                            Text("iPhone / iPad / Watch over WiFi")
                        }
                        HStack{
                            Toggle(isOn: $ideviceOverBLE) {}.toggleStyle(.switch)
                            Text("iPhone / iPad(Cellular) over BT")
                        }
                    }
                    Spacer()
                    VStack(alignment:.leading, spacing: 15){
                        HStack{
                            Toggle(isOn: $readAirpods) {}.toggleStyle(.switch)
                            Text("AirPods / Beats")
                        }
                        HStack{
                            Toggle(isOn: $readBTDevice) {}.toggleStyle(.switch)
                            Text("Other BT Device")
                        }
                    }
                    Spacer()
                }
                Divider().frame(width: 440)
                HStack{
                    Toggle(isOn: $cStatusOfBLE) {}.toggleStyle(.switch)
                    Text("Guess charging status of iDevices or BLE devices over BT")
                }
                HStack{
                    Toggle(isOn: $readBLEDevice) {}.toggleStyle(.switch)
                    Text("Try to get battery info from all BLE devices (Beta)")
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
                VStack(alignment:.leading, spacing: 15){
                    HStack{
                        Toggle(isOn: $intBattOnStatusBar) {}.toggleStyle(.switch)
                        Text("Show Mac Battery (relaunch needed)")
                    }
                    HStack{
                        Toggle(isOn: $statusBarBattPercent) {}.toggleStyle(.switch)
                        Text("Show Battery Percentage")
                    }
                }
            }
            .navigationTitle("AirBattery Settings")
            .tabItem {
                Image("statusbar")
                Text("StatusBar")
            }
            
            HStack(spacing: 0){
                VStack(alignment:.leading, spacing: 15){
                    HStack{
                        Toggle(isOn: $showMacOnWidget) {}.toggleStyle(.switch)
                        Text("Show Mac Battery")
                    }
                    HStack{
                        Toggle(isOn: $revListOnWidget) {}.toggleStyle(.switch)
                        Text("Reverse device list")
                    }
                }
            }
            .navigationTitle("AirBattery Settings")
            .tabItem {
                Image("widget")
                Text("Widget")
            }
        }
        .frame(width: 490, height: 170)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
