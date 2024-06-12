//
//  SettingsView.swift
//  AirBattery
//
//  Created by apple on 2023/9/7.
//

import SwiftUI
import ServiceManagement
import WidgetKit

struct Tooltip: NSViewRepresentable {
    let tooltip: String
    
    func makeNSView(context: NSViewRepresentableContext<Tooltip>) -> NSView {
        let view = NSView()
        view.toolTip = tooltip

        return view
    }
    
    func updateNSView(_ nsView: NSView, context: NSViewRepresentableContext<Tooltip>) {
    }
}

public extension View {
    func toolTip(_ toolTip: String) -> some View {
        self.overlay(Tooltip(tooltip: toolTip))
    }
}

struct SettingsView: View {
    @State private var blockedItems = [String]()
    @State private var editingIndex: Int?
    @State private var ib = getMacDeviceType().lowercased().contains("book")
    
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
    @AppStorage("fullyLevel") var fullyLevel = 100
    @AppStorage("alertSound") var alertSound = true
    @AppStorage("deviceOnWidget") var deviceOnWidget = ""
    @AppStorage("deviceName") var deviceName = "Mac"
    @AppStorage("updateInterval") var updateInterval = 1.0
    @AppStorage("widgetInterval") var widgetInterval = 0
    @AppStorage("twsMerge") var twsMerge = 5
    @AppStorage("nearCast") var nearCast = false
    @AppStorage("ncGroupID") var ncGroupID = ""
    @State var devices = [String]()
    
    var body: some View {
        TabView {
            VStack(spacing: 16) {
                HStack(spacing: 0){
                    VStack(alignment:.trailing, spacing: 16){
                        Text("Launch at Login")
                        Text("Show AirBattery on:")
                        //Text("Update Interval:")
                        Text("Remove Offline Device:")
                    }
                    VStack(alignment:.leading, spacing: 10){
                        HStack {
                            Toggle(isOn: $launchAtLogin) {}
                                .offset(x: 10)
                                .toggleStyle(.switch)
                                .onChange(of: launchAtLogin) { newValue in
                                    SMLoginItemSetEnabled("com.lihaoyun6.AirBatteryHelper" as CFString, newValue)
                                }
                            Spacer()
                            Button(action: {
                                updaterController.updater.checkForUpdates()
                            }, label: {
                                Text("Check for Updates…")
                            })
                        }
                        Picker("", selection: $showOn) {
                            Text("Dock").tag("dock")
                            Text("Menu Bar").tag("sbar")
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
                        
                        Picker("", selection: $disappearTime) {
                            Text("after 20min").tag(20)
                            Text("after 40min").tag(40)
                            Text("Never").tag(92233720368547758)
                        }.pickerStyle(.segmented)
                    }
                }.frame(width: 420)
                UpdaterSettingsView(updater: updaterController.updater)
            }
            .navigationTitle("AirBattery Settings")
            .tabItem { Label("General", systemImage: "gearshape") }
            
            VStack(spacing: 16){
                /*Text("Data Source:")
                    .font(.system(size: 14, weight: .bold))
                    .offset(y:-2)*/
                HStack(spacing:0){
                    Spacer()
                    Form(){
                        HStack{
                            Toggle(isOn: $readIDevice) {}.toggleStyle(.switch)
                            HStack(spacing: 2) {
                                Text("WiFi Scanner (iOS)")
                                SWInfoButton(showOnHover: false, fillMode: true, animatePopover: true, content: "Scan your iPhone / iPad / Apple Watch / VisionPro and other iDevices under the same router".local, primaryColor: NSColor(named: "my_blue") ?? NSColor.systemGray, preferredEdge: .minY)
                                    .frame(width: 19, height: 19)
                            }
                        }
                        HStack{
                            Toggle(isOn: $ideviceOverBLE) {}.toggleStyle(.switch)
                            HStack(spacing: 2) {
                                Text("BLE Scanner (iOS)")
                                SWInfoButton(showOnHover: false, fillMode: true, animatePopover: true, content: "Scan your iPhone and iPad(Cellular) via Bluetooth".local, primaryColor: NSColor(named: "my_blue") ?? NSColor.systemGray, preferredEdge: .minY)
                                    .frame(width: 19, height: 19)
                            }
                        }
                        HStack{
                            Toggle(isOn: $cStatusOfBLE) {}.toggleStyle(.switch)
                            HStack(spacing: 2) {
                                Text("Guess Power Status")
                                SWInfoButton(showOnHover: false, fillMode: true, animatePopover: true, content: "Guess if the iPhone / iPad or BLE device found by Bluetooth is charging".local, primaryColor: NSColor(named: "my_blue") ?? NSColor.systemGray, preferredEdge: .minY)
                                    .frame(width: 19, height: 19)
                            }
                        }
                    }
                    Spacer()
                    Form(){
                        HStack{
                            Toggle(isOn: $readBTDevice) {}.toggleStyle(.switch)
                            HStack(spacing: 2) {
                                Text("Bluetooth Scanner")
                                SWInfoButton(showOnHover: false, fillMode: true, animatePopover: true, content: "Get the battery usage of some Bluetooth peripherals (mouse, keyboard, headphone, etc.)\n\nPlease Note: Some devices cannot be listed even though macOS knows their battery usage".local, primaryColor: NSColor(named: "my_blue") ?? NSColor.systemGray, preferredEdge: .minY)
                                    .frame(width: 19, height: 19)
                            }
                        }
                        HStack{
                            Toggle(isOn: $readAirpods) {}.toggleStyle(.switch)
                            Text("Find AirPods / Beats")
                        }
                        HStack{
                            Toggle(isOn: $readBLEDevice) {}.toggleStyle(.switch)
                            HStack(spacing: 2) {
                                Text("Non-Apple BLE Devices")
                                SWInfoButton(showOnHover: false, fillMode: true, animatePopover: true, content: "Try to get the battery usage of any Bluetooth device that AirBattery can find\n\nWARNING: This is a BETA feature and may cause unexpected errors!".local, primaryColor: NSColor(named: "my_yellow") ?? NSColor.systemGray, preferredEdge: .minY)
                                    .frame(width: 19, height: 19)
                            }
                        }
                    }
                    Spacer()
                }
                //Divider().frame(width: 440)
                HStack {
                    Spacer()
                    HStack(spacing: 2) {
                        Picker("Update Interval", selection: $updateInterval) {
                            Text("Default").tag(1.0)
                            Text("Custom").tag(updateInterval == 1.0 ? 2.0 : updateInterval)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: updateInterval) { _ in
                            _ = createAlert(title: "Relaunch Required".local, message: "Restart AirBattery to apply this change.".local, button1: "OK".local).runModal()
                        }
                        TextField("", value: $updateInterval, formatter: NumberFormatter())
                            .textFieldStyle(.squareBorder)
                            .frame(width: 26)
                            .onChange(of: updateInterval) { newValue in
                                if newValue > 99.0 { updateInterval = 99.0 }
                                if newValue < 1.0 { updateInterval = 1.0 }
                            }
                            .disabled(updateInterval == 1.0)
                        Text("min")
                            .foregroundColor(updateInterval == 1.0 ? .secondary : .primary)
                    }.fixedSize()
                    Spacer()
                    HStack(spacing: 2) {
                        Text("Merge Limits").padding(.trailing, 5)
                        TextField("", value: $twsMerge, formatter: NumberFormatter())
                            .textFieldStyle(.squareBorder)
                            .frame(width: 26)
                            .onChange(of: twsMerge) { newValue in
                                if newValue > 99 { twsMerge = 99 }
                                if newValue < 1 { twsMerge = 1 }
                            }
                        Stepper("", value: $twsMerge)
                            .padding(.leading, -10)
                        SWInfoButton(showOnHover: false, fillMode: true, animatePopover: true, content: "If the difference in battery usage between the left and right earbuds is less than this value, AirBattery will show them as one device".local, primaryColor: NSColor(named: "my_blue") ?? NSColor.systemGray, preferredEdge: .minY)
                            .frame(width: 19, height: 19)
                    }.fixedSize()
                    Spacer()
                }
            }
            .navigationTitle("AirBattery Settings")
            .tabItem {
                Image("Nearbility")
                Text("Nearbility")
            }
            
            VStack {
                Form(){
                    HStack{
                        Text("Enable Nearcast")
                        Toggle(isOn: $nearCast) {}
                            .toggleStyle(.switch)
                            .onChange(of: nearCast) { newValue in
                                if newValue {
                                    if ncGroupID != "" && isGroudIDValid(id: ncGroupID) {
                                        if let server = netcastService {
                                            server.resume()
                                        } else {
                                            netcastService = MultipeerService(serviceType: String(ncGroupID.prefix(15)))
                                            netcastService?.resume()
                                        }
                                    } else {
                                        DispatchQueue.main.async { nearCast = false; ncGroupID = "" }
                                        _ = createAlert(
                                            title: "Invalid group ID".local,
                                            message: "Please create or enter a valid Group ID before use!",
                                            button1: "OK".local
                                        ).runModal()
                                    }
                                } else {
                                    if let server = netcastService { server.stop() }
                                }
                            }
                    }
                    HStack {
                        Text("Group ID").padding(.trailing, -8)
                        TextField("", text: $ncGroupID)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 220)
                            .disabled(nearCast)
                        Button(action: {
                            ncGroupID = "nc-" + randomString(length: 12) + randomString(type: 2, length: 8)
                        }, label: {
                            Text("New")
                        }).disabled(nearCast)
                    }
                }
                Text("Nearcast will send data in the LAN at the same interval as the Nearbility engine.\nYour data has been encrypted, so please do not tell your Group ID to others.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(0.6)
                    .padding(.top, 10).padding(.bottom, 1)
                Text("Do not add too many Macs to a group, this can be tiring for the router!")
                    .foregroundColor(.orange)
                    .opacity(0.7)
            }
            .navigationTitle("AirBattery Settings")
            .tabItem {
                Image("Nearcast")
                Text("Nearcast")
            }
            
            HStack(spacing: 0){
                VStack(alignment:.trailing, spacing: 18){
                    Text("Appearance:")
                    HStack(spacing: 2) {
                        SWInfoButton(showOnHover: false, fillMode: true, animatePopover: true, content: "Show or hide this Mac's built-in battery in the Dock icon".local, primaryColor: NSColor(named: "my_blue") ?? NSColor.systemGray, preferredEdge: .minY)
                            .frame(width: 19, height: 19)
                        Text("Built-in Battery:").foregroundColor(ib ? Color.primary : Color.secondary)
                    }
                    HStack(spacing: 2) {
                        SWInfoButton(showOnHover: false, fillMode: true, animatePopover: true, content: "Cycle through all found devices in the Dock icon".local, primaryColor: NSColor(named: "my_blue") ?? NSColor.systemGray, preferredEdge: .minY)
                            .frame(width: 19, height: 19)
                        Text("Carousel Mode:")
                    }.offset(y: 2)
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
                    }
                    .pickerStyle(.segmented)
                    .disabled(!ib)
                    Picker("", selection: $rollingMode) {
                        Text("Automatic").tag("auto")
                        Text("On").tag("on")
                        Text("Off").tag("off")
                    }.pickerStyle(.segmented)
                }.frame(width: 300, alignment: .leading)
            }
            .navigationTitle("AirBattery Settings")
            .tabItem { Label("Dock Icon", systemImage: "menubar.dock.rectangle") }
            
            HStack(spacing: 0){
                VStack(alignment:.leading, spacing: 15){
                    HStack{
                        Toggle(isOn: $intBattOnStatusBar) {}
                            .toggleStyle(.switch)
                            .onChange(of: intBattOnStatusBar) { _ in
                                _ = createAlert(title: "Relaunch Required".local, message: "Restart AirBattery to apply this change.".local, button1: "OK".local).runModal()
                            }
                        Text("Dynamic Battery Icon").foregroundColor(ib ? Color.primary : Color.secondary)
                    }
                    HStack{
                        Toggle(isOn: $statusBarBattPercent) {}.toggleStyle(.switch)
                        Text("Show Battery Percentage").foregroundColor(ib ? Color.primary : Color.secondary)
                    }
                    HStack{
                        Toggle(isOn: $hidePercentWhenFull) {}.toggleStyle(.switch)
                        Text("Hidden Percentage above 90%").foregroundColor(statusBarBattPercent ? Color.primary : Color.secondary)
                    }.disabled(!statusBarBattPercent)
                }.disabled(!ib)
            }
            .navigationTitle("AirBattery Settings")
            .tabItem { Label("Menu Bar", systemImage: "menubar.rectangle") }
            
            VStack(alignment:.center, spacing: 14){
                HStack{
                    Toggle(isOn: $showMacOnWidget) {}.toggleStyle(.switch).disabled(!ib)
                    Text("Show Mac Built-in Battery").foregroundColor(ib ? Color.primary : Color.secondary)
                    Spacer()
                    Toggle(isOn: $revListOnWidget) {}.toggleStyle(.switch)
                    Text("Reverse the Device List")
                }
                HStack(spacing: 3) {
                    Text("Refresh Interval")
                    SWInfoButton(showOnHover: false, fillMode: true, animatePopover: true, content: "System Default: Determined by macOS\n\nNearbility: Same as Nearbility setting".local, primaryColor: NSColor(named: "my_blue") ?? NSColor.systemGray, preferredEdge: .maxX)
                        .frame(width: 19, height: 19)
                    Picker("", selection: $widgetInterval) {
                        Text("System Default").tag(-1)
                        Text("Nearbility").tag(0)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: widgetInterval) { _ in
                        _ = createAlert(title: "Relaunch Required".local, message: "Restart AirBattery to apply this change.".local, button1: "OK".local).runModal()
                    }
                }
                if #unavailable(macOS 14) {
                    Picker("Single Device Widget", selection: $deviceOnWidget) {
                        Text("Not Set").tag("")
                        if ib { Text(deviceName).tag(deviceName) }
                        ForEach(devices, id: \.self) { device in
                            Text(device).tag(device)
                        }
                        if !devices.contains(deviceOnWidget) && deviceOnWidget != deviceName && deviceOnWidget != "" {
                            Text(deviceOnWidget).tag(deviceOnWidget)
                        }
                    }.onChange(of: deviceOnWidget) { _ in _ = AirBatteryModel.singleDeviceName() }
                } else {
                    Spacer().frame(height: 1)
                }
                HStack {
                    Button(action: {
                        AirBatteryModel.writeData()
                        WidgetCenter.shared.reloadAllTimelines()
                    }, label: {
                        Text("Reload All Widgets")
                            .foregroundColor(.orange)
                    })
                }
            }
            .onAppear { devices = AirBatteryModel.getAll(noFilter: true).filter({ $0.hasBattery }).map({ $0.deviceName }) }
            .onReceive(dockTimer) { _ in
                if #unavailable(macOS 14) {
                    devices = AirBatteryModel.getAll(noFilter: true).filter({ $0.hasBattery }).map({ $0.deviceName })
                }
            }
            .navigationTitle("AirBattery Settings")
            .frame(width: 420)
            .tabItem {
                Image("widget")
                Text("Widget")
            }
            HStack(spacing: 0){
                VStack(alignment:.trailing, spacing: 22){
                    Text("Notification Sound:")
                    Text("Low Battery Threshold:")
                    Text("Fully Charged Threshold:")
                }
                VStack(alignment:.leading, spacing: 15){
                    Toggle(isOn: $alertSound) {}
                        .offset(x: 10)
                        .toggleStyle(.switch)
                    Picker("", selection: $alertLevel) {
                        Text("20%").tag(20)
                        Text("15%").tag(15)
                        Text("10%").tag(10)
                    }.pickerStyle(.segmented)
                    Picker("", selection: $fullyLevel) {
                        Text("100%").tag(100)
                        Text("90%").tag(90)
                        Text("80%").tag(80)
                    }.pickerStyle(.segmented)
                }.frame(width: 240, alignment: .leading)
            }
            .navigationTitle("AirBattery Settings")
            .tabItem { Label("Notification", systemImage: "bell") }
            VStack(alignment:.center, spacing: 15) {
                ZStack(alignment: Alignment(horizontal: .trailing, vertical: .bottom)) {
                    List {
                        ForEach(0..<blockedItems.count, id: \.self) { index in
                            HStack {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                                    .onTapGesture { if editingIndex == nil { blockedItems.remove(at: index) } }
                                if editingIndex == index {
                                    TextField("Enter text", text: Binding(
                                        get: { blockedItems[index] },
                                        set: { blockedItems[index] = $0 }
                                    ), onCommit: {
                                        editingIndex = nil
                                    })
                                } else {
                                    Text(blockedItems[index])
                                        .onTapGesture {
                                            editingIndex = index
                                        }
                                }
                            }
                        }
                    }.padding(10)
                    Button(action: {
                        blockedItems.append("Click to enter the device name".local)
                        //editingIndex = blockedItems.count - 1
                    }) {
                        Image(systemName: "plus.square.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }.buttonStyle(.plain).padding([.trailing, .bottom], 10)
                }
                .onAppear {
                    blockedItems = (UserDefaults.standard.object(forKey: "blockedDevices") as? [String]) ?? [String]()
                }
                .onChange(of: blockedItems) { b in
                    UserDefaults.standard.setValue(b, forKey: "blockedDevices")
                }
            }
            .navigationTitle("AirBattery Settings")
            .tabItem { Label("Blacklist", systemImage: "eye.slash") }
        }.frame(width: 520, height: 160)
    }
}
