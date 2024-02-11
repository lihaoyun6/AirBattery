//
//  DockBatteryApp.swift
//  DockBattery
//
//  Created by apple on 2023/9/4.
//
import SwiftUI
//import CoreLocation
//import CoreBluetooth

@main
struct DockBatteryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    @AppStorage("weatherMode") var weatherMode = "off"
    @AppStorage("dockTheme") var dockTheme = "battery"
    @AppStorage("forceWeather") var forceWeather = false
    @AppStorage("machineName") var machineName = "Mac"
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let window = NSApplication.shared.windows.first { window.close() }
        NSApp.dockTile.contentView = NSHostingView(rootView: InitView())
        NSApp.dockTile.display()
        machineName = getMachineName()
        let airpodsBattery = AirpodsBattery()
        airpodsBattery.startScanning()
        let bluetoothBattery = BluetoothBattery()
        bluetoothBattery.startScanning()
        let ideviceBattery = IDeviceBattery()
        ideviceBattery.startScanning()
        let weathers = Weathers()
        weathers.startGetting()
    }
    
    func getMachineName() -> String {
        guard let result = process(path: "/usr/sbin/system_profiler", arguments: ["SPHardwareDataType", "-json"]) else { return "Mac" }
        if let json = try? JSONSerialization.jsonObject(with: Data(result.utf8), options: []) as? [String: Any],
           let SPHardwareDataTypeRaw = json["SPHardwareDataType"] as? [Any],
           let SPHardwareDataType = SPHardwareDataTypeRaw[0] as? [String: Any],
           let model = SPHardwareDataType["machine_name"] as? String{
            return model
        }
        return "Mac"
    }
    
    @objc func openCalendar() {
        if let photosApp = FileManager.default.urls(
                for: .applicationDirectory,
                in: .systemDomainMask
            ).first?.appendingPathComponent("Calendar.app") {
                NSWorkspace.shared.open(photosApp)
            }
    }
    @objc func openBattery() {
        let str = "x-apple.systempreferences:com.apple.preference.battery"
        if let url = NSURL(string: str) { NSWorkspace.shared.open(url as URL) }
    }
    @objc func openAboutPanel() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }
    @objc func openSettingPanel() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14, *) {
            NSApp.mainMenu?.items.first?.submenu?.item(at: 2)?.performAction()
        }else if #available(macOS 13, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
    @objc func foreceWeather() { forceWeather = true }
    /*@objc func openLocation() {
        let originalString = "http://maps.apple.com/?ll=\(location)"
        if let encodedString = originalString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            if let url = URL(string: encodedString) { NSWorkspace.shared.open(url as URL) }
        }
        
    }*/
    
    let dockMenu = NSMenu()
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let now = Double(Date().timeIntervalSince1970)
        let ibStatus = getPowerState()
        dockMenu.removeAllItems()
        if ibStatus.hasBattery {
            let level = ibStatus.batteryLevel
            let batteryColor = getPowerColor(level, emoji: true)
            var timeText = ""
            if ibStatus.isCharging { timeText = "Time until full: ".local + "\(ibStatus.timeLeft)" } else { timeText = "Remaining time: ".local + "\(ibStatus.timeLeft)" }
            let alte = NSMenuItem(title: "[\(timeText)]  \(machineName)", action: nil, keyEquivalent: "")
            alte.isAlternate = true
            alte.keyEquivalentModifierMask = .option
            dockMenu.addItem(withTitle:"\(batteryColor) \(getMonoNum(level))\(ibStatus.isCharging ? " ⚡︎ " : "﹪")  \(machineName)", action: nil, keyEquivalent: "")
            dockMenu.addItem(alte)
        }
        dockMenu.addItem(NSMenuItem.separator())
        /*dockMenu.addItem(withTitle:batteryText, action: nil, keyEquivalent: "")
        dockMenu.addItem(NSMenuItem.separator())
        dockMenu.addItem(withTitle:"Battery Settings".local, action: #selector(openBattery), keyEquivalent: ""
        if dockTheme == "multinfo" {
            dockMenu.addItem(withTitle:"Open Calendar".local, action: #selector(openCalendar), keyEquivalent: "")
            if weatherMode != "off" { dockMenu.addItem(withTitle:"Refresh Weather Data".local, action: #selector(foreceWeather), keyEquivalent: "") }
        }*/
        //dockMenu.addItem(NSMenuItem.separator())
        for d in AirBatteryModel.btDevices {
            //if now - d.lastUpdate > 600 { continue }
            let timePast = min(Int((now - d.lastUpdate) / 60), 99)
            let batteryColor = getPowerColor(d.batteryLevel, emoji: true)
            let alte = NSMenuItem(title: "[\(timePast == 99 ? " >" : "↻")\(getMonoNum(timePast,count:2))" + " mins ago".local + "]  \(timePast > 10 ? "⚠︎ " : "")\(d.deviceName)", action: nil, keyEquivalent: "")
            alte.isAlternate = true
            alte.keyEquivalentModifierMask = .option
            dockMenu.addItem(withTitle:"\(batteryColor) \(getMonoNum(d.batteryLevel))\(d.isCharging != 0 ? " ⚡︎ " : "﹪")  \(timePast > 10 ? "⚠︎ " : "")\(d.deviceName)", action: nil, keyEquivalent: "")
            dockMenu.addItem(alte)
        }
        dockMenu.addItem(NSMenuItem.separator())
        for d in AirBatteryModel.bleDevices + AirBatteryModel.iDevices {
            //if now - d.lastUpdate > 600 { continue }
            let timePast = min(Int((now - d.lastUpdate) / 60), 99)
            let batteryColor = getPowerColor(d.batteryLevel, emoji: true)
            let alte = NSMenuItem(title: "[\(timePast == 99 ? " >" : "↻")\(getMonoNum(timePast,count:2))" + " mins ago".local + "]  \(timePast > 10 ? "⚠︎ " : "")\(d.deviceName)", action: nil, keyEquivalent: "")
            alte.isAlternate = true
            alte.keyEquivalentModifierMask = .option
            dockMenu.addItem(withTitle:"\(batteryColor) \(getMonoNum(d.batteryLevel))\(d.isCharging != 0 ? " ⚡︎ " : "﹪")  \(timePast > 10 ? "⚠︎ " : "")\(d.deviceName)", action: nil, keyEquivalent: "")
            dockMenu.addItem(alte)
            if let subds = d.subDevices {
                for subd in subds {
                    let timePast = min(Int((now - subd.lastUpdate) / 60), 99)
                    let subBatteryColor = getPowerColor(subd.batteryLevel, emoji: true)
                    let alte = NSMenuItem(title: "[\(timePast == 99 ? " >" : "↻")\(getMonoNum(timePast,count:2))" + " mins ago".local + "]  \(timePast > 10 ? "⚠︎ " : "")\(subd.deviceName)", action: nil, keyEquivalent: "")
                    alte.isAlternate = true
                    alte.keyEquivalentModifierMask = .option
                    dockMenu.addItem(withTitle:"\(subBatteryColor) \(getMonoNum(subd.batteryLevel))\(subd.isCharging != 0 ? " ⚡︎ " : "﹪")  \(timePast > 10 ? "⚠︎ " : "")\(subd.deviceName)", action: nil, keyEquivalent: "")
                    dockMenu.addItem(alte)
                }
            }
            dockMenu.addItem(NSMenuItem.separator())
        }
        if dockTheme == "multinfo" { if weatherMode != "off" {
            dockMenu.addItem(withTitle:"Refresh Weather Data".local, action: #selector(foreceWeather), keyEquivalent: "") }
            dockMenu.addItem(NSMenuItem.separator())
        }
        dockMenu.addItem(withTitle:"Settings...".local, action: #selector(openSettingPanel), keyEquivalent: "")
        dockMenu.addItem(withTitle:"About DockBattery".local, action: #selector(openAboutPanel), keyEquivalent: "")
        return dockMenu
    }
    public func process(path: String, arguments: [String]) -> String? {
        let task = Process()
        task.launchPath = path
        task.arguments = arguments
        
        let outputPipe = Pipe()
        defer {
            outputPipe.fileHandleForReading.closeFile()
        }
        task.standardOutput = outputPipe
        
        do {
            try task.run()
        } catch let error {
            print("system_profiler SPMemoryDataType: \(error.localizedDescription)")
            return nil
        }
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: outputData, as: UTF8.self)
        
        if output.isEmpty {
            return nil
        }
        
        return output
    }
}
