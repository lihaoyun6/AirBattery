//
//  DockBatteryApp.swift
//  DockBattery
//
//  Created by apple on 2023/9/4.
//
import SwiftUI
import AppKit
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

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    @AppStorage("weatherMode") var weatherMode = "off"
    @AppStorage("dockTheme") var dockTheme = "battery"
    //@AppStorage("forceWeather") var forceWeather = false
    @AppStorage("machineName") var machineName = "Mac"
    @AppStorage("showOn") var showOn = "dock"
    @AppStorage("disappearTime") var disappearTime = 20
    
    var statusBarItem: NSStatusItem!
    var menu: NSMenu = NSMenu()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if showOn == "sbar" { NSApp.setActivationPolicy(.accessory) }
        if let window = NSApplication.shared.windows.first { window.close() }
        
        machineName = getMachineName()
        let airpodsBattery = AirpodsBattery()
        airpodsBattery.startScanning()
        let bluetoothBattery = BluetoothBattery()
        bluetoothBattery.startScanning()
        let ideviceBattery = IDeviceBattery()
        ideviceBattery.startScanning()
        let weathers = Weathers()
        weathers.startGetting()
        
        menu.delegate = self
        statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        statusBarItem.menu = menu
        if let button = statusBarItem.button {
            button.image = NSImage(named: "menuItem")
        }
        if showOn == "dock" { statusBarItem.isVisible = false }
        
        NSApp.dockTile.contentView = NSHostingView(rootView: InitView(statusBarItem: statusBarItem))
        NSApp.dockTile.display()
    }
    
    func getImageResize(_ i: NSImage) -> NSSize {
        let w = i.size.width
        let h = i.size.height
        if w > h {
            let r = Double(h)/w
            return NSSize(width: 16, height: 16*r)
        }
        if w < h {
            let r = Double(w)/h
            return NSSize(width: 16, height: 16*r)
        }
        return NSSize(width: 16, height: 16)
    }
    
    @objc func blank() {}
    
    func menuWillOpen(_ menu: NSMenu) {
        getMenu()
    }
    
    /*@objc func openCalendar() {
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
    }*/
     
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
    //@objc func foreceWeather() { forceWeather = true }
    /*@objc func openLocation() {
        let originalString = "http://maps.apple.com/?ll=\(location)"
        if let encodedString = originalString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            if let url = URL(string: encodedString) { NSWorkspace.shared.open(url as URL) }
        }
        
    }*/
    
    //let dockMenu = NSMenu()
    
    func getMenu(fromDock: Bool = false) {
        let now = Double(Date().timeIntervalSince1970)
        let ibStatus = getPowerState()
        menu.removeAllItems()
        if ibStatus.hasBattery {
            let level = ibStatus.batteryLevel
            let batteryColor = getPowerColor(level, emoji: true)
            var timeText = ""
            if ibStatus.isCharging { timeText = "Time until full: ".local + "\(ibStatus.timeLeft)" } else { timeText = "Remaining time: ".local + "\(ibStatus.timeLeft)" }
            let main = NSMenuItem(title: "\(batteryColor) \(getMonoNum(level))\(ibStatus.isCharging ? " ⚡︎ " : "﹪")  \(machineName)", action: #selector(blank), keyEquivalent: "")
            let alte = NSMenuItem(title: "[\(timeText)]  \(machineName)", action: nil, keyEquivalent: "")
            alte.isAlternate = true
            alte.keyEquivalentModifierMask = .option
            if let image = getMacIcon(machineName) {
                image.size = getImageResize(image)
                main.image = image
                alte.image = image
            }
            menu.addItem(main)
            menu.addItem(alte)
        } else {
            menu.addItem(withTitle: machineName, action: #selector(blank), keyEquivalent: "")
        }
        menu.addItem(NSMenuItem.separator())
        /*menu.addItem(withTitle:batteryText, action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle:"Battery Settings".local, action: #selector(openBattery), keyEquivalent: ""
        if dockTheme == "multinfo" {
            menu.addItem(withTitle:"Open Calendar".local, action: #selector(openCalendar), keyEquivalent: "")
            if weatherMode != "off" { menu.addItem(withTitle:"Refresh Weather Data".local, action: #selector(foreceWeather), keyEquivalent: "") }
        }*/
        //menu.addItem(NSMenuItem.separator())
        for d in AirBatteryModel.btDevices {
            //if now - d.lastUpdate > 600 { continue }
            let timePast = min(Int((now - d.lastUpdate) / 60), 99)
            if timePast >= disappearTime && disappearTime != 999 { continue }
            let batteryColor = getPowerColor(d.batteryLevel, emoji: true)
            let main = NSMenuItem(title: "\(batteryColor) \(getMonoNum(d.batteryLevel))\(d.isCharging != 0 ? " ⚡︎ " : "﹪")  \(timePast > 10 ? "⚠︎ " : "")\(d.deviceName)", action: #selector(blank), keyEquivalent: "")
            let alte = NSMenuItem(title: "[\(timePast == 99 ? " >" : "↻")\(getMonoNum(timePast,count:2))" + " mins ago".local + "]  \(timePast > 10 ? "⚠︎ " : "")\(d.deviceName)", action: nil, keyEquivalent: "")
            alte.isAlternate = true
            alte.keyEquivalentModifierMask = .option
            if let image = getDeviceIcon(d) {
                image.size = getImageResize(image)
                main.image = image
                alte.image = image
            }
            menu.addItem(main)
            menu.addItem(alte)
        }
        menu.addItem(NSMenuItem.separator())
        for d in AirBatteryModel.bleDevices + AirBatteryModel.iDevices {
            //if now - d.lastUpdate > 600 { continue }
            let timePast = min(Int((now - d.lastUpdate) / 60), 99)
            if timePast >= disappearTime && disappearTime != 999 { continue }
            let batteryColor = getPowerColor(d.batteryLevel, emoji: true)
            let main = NSMenuItem(title: "\(batteryColor) \(getMonoNum(d.batteryLevel))\(d.isCharging != 0 ? " ⚡︎ " : "﹪")  \(timePast > 10 ? "⚠︎ " : "")\(d.deviceName)", action: #selector(blank), keyEquivalent: "")
            let alte = NSMenuItem(title: "[\(timePast == 99 ? " >" : "↻")\(getMonoNum(timePast,count:2))" + " mins ago".local + "]  \(timePast > 10 ? "⚠︎ " : "")\(d.deviceName)", action: nil, keyEquivalent: "")
            alte.isAlternate = true
            alte.keyEquivalentModifierMask = .option
            if let image = getDeviceIcon(d) {
                image.size = getImageResize(image)
                main.image = image
                alte.image = image
            }
            menu.addItem(main)
            menu.addItem(alte)
            if let subds = d.subDevices {
                for subd in subds {
                    let timePast = min(Int((now - subd.lastUpdate) / 60), 99)
                    let subBatteryColor = getPowerColor(subd.batteryLevel, emoji: true)
                    let main = NSMenuItem(title: "\(subBatteryColor) \(getMonoNum(subd.batteryLevel))\(subd.isCharging != 0 ? " ⚡︎ " : "﹪")  \(timePast > 10 ? "⚠︎ " : "")\(subd.deviceName)", action: #selector(blank), keyEquivalent: "")
                    let alte = NSMenuItem(title: "[\(timePast == 99 ? " >" : "↻")\(getMonoNum(timePast,count:2))" + " mins ago".local + "]  \(timePast > 10 ? "⚠︎ " : "")\(subd.deviceName)", action: nil, keyEquivalent: "")
                    alte.isAlternate = true
                    alte.keyEquivalentModifierMask = .option
                    if let image = getDeviceIcon(subd) {
                        image.size = getImageResize(image)
                        main.image = image
                        alte.image = image
                    }
                    menu.addItem(main)
                    menu.addItem(alte)
                }
            }
            menu.addItem(NSMenuItem.separator())
        }
        menu.addItem(withTitle:"Settings...".local, action: #selector(openSettingPanel), keyEquivalent: "")
        menu.addItem(withTitle:"About DockBattery".local, action: #selector(openAboutPanel), keyEquivalent: "")
        if !fromDock {
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle:"Quit DockBattery".local, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        }
    }
    
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        getMenu(fromDock: true)
        return menu
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
            print("system_profiler: \(error.localizedDescription)")
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
