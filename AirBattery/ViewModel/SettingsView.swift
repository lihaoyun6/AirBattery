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
    //@AppStorage("useDeviceName") var useDeviceName = true
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
    @AppStorage("hidePercentWhenFull") var hidePercentWhenFull = false
    @AppStorage("launchAtLogin") var launchAtLogin = false
    @AppStorage("alertLevel") var alertLevel = 10
    @AppStorage("alertSound") var alertSound = true
    @AppStorage("deviceOnWidget") var deviceOnWidget = ""
    @AppStorage("deviceName") var deviceName = "Mac"
    @AppStorage("updateInterval") var updateInterval = 1.0
    @State var devices = [String]()
    
    var body: some View {
        TabView {
            HStack(spacing: 0){
                VStack(alignment:.trailing, spacing: 22){
                    Text("Launch at Login")
                    Text("Show AirBattery on:")
                    Text("Update Interval:")
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
                        Text("None").tag("none")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: showOn) { newValue in
                        switch newValue {
                        case "sbar":
                            statusBarItem.isVisible = true
                            NSApp.setActivationPolicy(.accessory)
                        case "both":
                            statusBarItem.isVisible = true
                            NSApp.setActivationPolicy(.regular)
                        case "dock":
                            statusBarItem.isVisible = false
                            NSApp.setActivationPolicy(.regular)
                        default:
                            statusBarItem.isVisible = false
                            NSApp.setActivationPolicy(.accessory)
                        }
                    }
                    Picker("", selection: $updateInterval) {
                        Text("Short").tag(1.0)
                        Text("Medium").tag(2.0)
                        Text("Long").tag(3.0)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: updateInterval) { _ in
                        _ = AppDelegate.shared.createAlert(title: "Relaunch Required".local, message: "Restart AirBattery to apply this change.".local, button1: "OK".local).runModal()
                    }
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
                    Text("Carousel mode:")
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
                        Toggle(isOn: $intBattOnStatusBar) {}
                            .toggleStyle(.switch)
                            .onChange(of: intBattOnStatusBar) { _ in
                                _ = AppDelegate.shared.createAlert(title: "Relaunch Required".local, message: "Restart AirBattery to apply this change.".local, button1: "OK".local).runModal()
                            }
                        Text("Show Built-in Battery")
                    }
                    HStack{
                        Toggle(isOn: $statusBarBattPercent) {}.toggleStyle(.switch)
                        Text("Show Battery Percentage")
                    }
                    HStack{
                        Toggle(isOn: $hidePercentWhenFull) {}.toggleStyle(.switch)
                        Text("Hidden Percentage above 90%")
                    }.disabled(!statusBarBattPercent)
                }
            }
            .navigationTitle("AirBattery Settings")
            .tabItem {
                Image("statusbar")
                Text("StatusBar")
            }
            
            HStack(spacing: 0){
                VStack(alignment:.center, spacing: 15){
                    HStack{
                        Toggle(isOn: $showMacOnWidget) {}.toggleStyle(.switch)
                        Text("Show Built-in Battery")
                        Spacer()
                        Toggle(isOn: $revListOnWidget) {}.toggleStyle(.switch)
                        Text("Reverse Device List")
                    }.frame(width: 360)
                    Picker("Single Device Widget", selection: $deviceOnWidget) {
                        Text(deviceName).tag(deviceName)
                        ForEach(devices, id: \.self) { device in
                            Text(device).tag(device)
                        }
                        if !devices.contains(deviceOnWidget) {
                            Text(deviceOnWidget).tag(deviceOnWidget)
                        }
                    }
                    .frame(width: 360)
                    .onChange(of: deviceOnWidget) { _ in _ = AirBatteryModel.singleDeviceName() }
                }
            }
            .onAppear { devices = AirBatteryModel.getAll(noFilter: true).map({ $0.deviceName }) }
            .onReceive(dockTimer) { _ in devices = AirBatteryModel.getAll(noFilter: true).map({ $0.deviceName }) }
            .navigationTitle("AirBattery Settings")
            .tabItem {
                Image("widget")
                Text("Widget")
            }
            HStack(spacing: 0){
                VStack(alignment:.trailing, spacing: 22){
                    Text("Notification Sound:")
                    Text("Battery Level Threshold:")
                }
                VStack(alignment:.leading, spacing: 15){
                    Toggle(isOn: $alertSound) {}
                        .offset(x: 10)
                        .toggleStyle(.switch)
                    Picker("", selection: $alertLevel) {
                        Text("10%").tag(10)
                        Text("15%").tag(15)
                        Text("20%").tag(20)
                    }.pickerStyle(.segmented)
                }.frame(width: 240, alignment: .leading)
            }
            .navigationTitle("AirBattery Settings")
            .tabItem { Label(" Alert ", systemImage: "bell") }
            VStack(alignment:.center, spacing: 15) {
                Form(){
                    UpdaterSettingsView(updater: updaterController.updater)
                }
                Button(action: {
                    updaterController.updater.checkForUpdates()
                }, label: {
                    Text("Check for Updates…")
                })
            }
            .navigationTitle("AirBattery Settings")
            .tabItem { Label("Update", systemImage: "chevron.up.circle") }
        }
        .frame(width: 490, height: 170)
    }
}
