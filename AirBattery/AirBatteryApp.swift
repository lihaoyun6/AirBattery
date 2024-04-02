//
//  AirBatteryApp.swift
//  AirBattery
//
//  Created by apple on 2023/9/4.
//
import AppKit
import SwiftUI
import WidgetKit
import UserNotifications

@main
struct AirBatteryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    @AppStorage("showOn") var showOn = "both"
    @AppStorage("machineName") var machineName = "Mac"
    @AppStorage("launchAtLogin") var launchAtLogin = false
    @AppStorage("intBattOnStatusBar") var intBattOnStatusBar = true
    @AppStorage("statusBarBattPercent") var statusBarBattPercent = false
    @AppStorage("hidePercentWhenFull") var hidePercentWhenFull = false
    //var blackList = (UserDefaults.standard.object(forKey: "blackList") ?? []) as! [String]
    
    var statusBarItem: NSStatusItem!
    var statusMenu: NSMenu = NSMenu()
    var menu: NSMenu = NSMenu()
    var dockWindow = NSWindow()
    let bleBattery = BLEBattery()
    let magicBattery = MagicBattery()
    let ideviceBattery = IDeviceBattery()
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // 用户点击 Dock 图标时会调用这个方法
        if dockWindow.isVisible {
            dockWindow.orderOut(nil)
        } else {
            var allDevices = AirBatteryModel.getAll()
            let ibStatus = InternalBattery.status
            if ibStatus.hasBattery { allDevices.insert(ibToAb(ibStatus), at: 0) }
            let contentViewSwiftUI = popover(fromDock: true, allDevices: allDevices)
            let contentView = NSHostingView(rootView: contentViewSwiftUI)
            var hiddenRow = 0
            if AirBatteryModel.getBlackList().count > 0 { hiddenRow = 1 }
            var mouse = NSEvent.mouseLocation
            if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) {
                mouse = CGPoint(x: mouse.x, y: max(mouse.y, screen.visibleFrame.origin.y))
            }
            contentView.frame = NSRect(x: mouse.x-176, y: mouse.y+20, width: 352, height: CGFloat((max(allDevices.count,1)+hiddenRow)*37+25))
            dockWindow = NSWindow(contentRect: contentView.frame, styleMask: [.fullSizeContentView], backing: .buffered, defer: false)
            dockWindow.title = "AirBattery Dock Window"
            dockWindow.level = .popUpMenu
            dockWindow.contentView = contentView
            dockWindow.isOpaque = false
            dockWindow.backgroundColor = NSColor.clear
            dockWindow.contentView?.wantsLayer = true
            dockWindow.contentView?.layer?.cornerRadius = 6
            dockWindow.contentView?.layer?.masksToBounds = true
            dockWindow.orderFront(nil)
        }
        return true
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if showOn == "sbar" { NSApp.setActivationPolicy(.accessory) }
        //if let window = NSApplication.shared.windows.first { window.close() }
        launchAtLogin = NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.lihaoyun6.AirBatteryHelper" }
        print("⚙️ Launch AirBattery at login = \(launchAtLogin)")
        
        machineName = getMachineName()
        if let result = process(path: "/usr/sbin/system_profiler", arguments: ["SPBluetoothDataType", "-json"]) { SPBluetoothDataModel.data = result }
        AirBatteryModel.writeData()
        WidgetCenter.shared.reloadAllTimelines()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error { print("⚠️ Notification authorization denied: \(error.localizedDescription)") }
        }
        
        bleBattery.startScan()
        magicBattery.startScan()
        ideviceBattery.startScan()
        
        menu.delegate = self
        statusMenu.delegate = self
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem.menu = statusMenu
        if let button = statusBarItem.button {
            button.target = self
            //button.action = #selector(statusBarButtonClicked(_:))
            //button.sendAction(on: [.leftMouseDown, .rightMouseDown])
            let ib = getPowerState()
            
            if ib.hasBattery && intBattOnStatusBar {
                let iconView = NSHostingView(rootView: mainBatteryView(statusBarItem: statusBarItem))
                iconView.frame = NSRect(x: 0, y: 0, width: statusBarBattPercent ? 76 : 42, height: 21.5)
                if hidePercentWhenFull && ib.batteryLevel >= 90 {
                    iconView.frame = NSRect(x: 0, y: 0, width: 42, height: 21.5)
                }
                button.addSubview(iconView)
                button.frame = iconView.frame
            } else {
                let image = NSImage(named: "menuItem")!
                button.image = image
            }
        }
        if showOn == "dock" { statusBarItem.isVisible = false }
        print("⚙️ Icon mode = \(showOn)")
        NSApp.dockTile.contentView = NSHostingView(rootView: MultiBatteryView(statusBarItem: statusBarItem))
        NSApp.dockTile.display()
    }
    
    @objc func blank() {}
    
    /*@objc func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        if event.type == NSEvent.EventType.rightMouseUp {
            getMenu(fromDock: false)
            statusBarItem.menu = menu
            statusBarItem.button?.performClick(nil)
            statusBarItem.menu = nil
        } else {
            //getStatusBarView()
            statusBarItem.menu = statusMenu
            statusBarItem.button?.performClick(nil)
            statusBarItem.menu = nil
        }
    }*/
    
    @objc func addToBlackList(_ sender: NSMenuItem) {
        var blackList = (UserDefaults.standard.object(forKey: "blackList") ?? []) as! [String]
        let deviceName = (sender.representedObject ?? "") as! String
        if deviceName != "" {
            blackList.append(deviceName)
            UserDefaults.standard.set(blackList, forKey: "blackList")
        }
    }
    
    @objc func removeFromBlackList(_ sender: NSMenuItem) {
        var blackList = (UserDefaults.standard.object(forKey: "blackList") ?? []) as! [String]
        let deviceName = (sender.representedObject ?? "") as! String
        if deviceName != "" {
            blackList.removeAll { $0 == deviceName }
            UserDefaults.standard.set(blackList, forKey: "blackList")
        }
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        dockWindow.orderOut(nil)
        var allDevices = AirBatteryModel.getAll()
        let ibStatus = InternalBattery.status
        if ibStatus.hasBattery { allDevices.insert(ibToAb(ibStatus), at: 0) }
        let contentViewSwiftUI = popover(fromDock: false, allDevices: allDevices)
        let contentView = NSHostingView(rootView: contentViewSwiftUI)
        var hiddenRow = 0
        if AirBatteryModel.getBlackList().count > 0 { hiddenRow = 1 }
        contentView.frame = NSRect(x: 0, y: 0, width: 352, height: (max(allDevices.count,1)+hiddenRow)*37+15)
        let menuItem = NSMenuItem()
        menuItem.view = contentView
        statusMenu.removeAllItems()
        statusMenu.addItem(menuItem)
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
    func getMenu(fromDock: Bool = false) {
        let now = Double(Date().timeIntervalSince1970)
        let ibStatus = InternalBattery.status
        menu.removeAllItems()
        if ibStatus.hasBattery {
            let level = ibStatus.batteryLevel
            let batteryColor = getPowerColor(level, emoji: true)
            var timeText = ""
            if ibStatus.isCharging { timeText = "Time until full: ".local + "\(ibStatus.timeLeft)" } else { timeText = "Time until empty: ".local + "\(ibStatus.timeLeft)" }
            let main = NSMenuItem(title: "\(batteryColor) \(getMonoNum(level))\(ibStatus.isCharging ? " ⚡︎ " : "﹪")  \(machineName)", action: #selector(blank), keyEquivalent: "")
            let alte = NSMenuItem(title: "[\(timeText)]  \(machineName)", action: nil, keyEquivalent: "")
            alte.isAlternate = true
            alte.keyEquivalentModifierMask = .option
            menu.addItem(main)
            menu.addItem(alte)
        } else {
            menu.addItem(withTitle: machineName, action: #selector(blank), keyEquivalent: "")
        }
        menu.addItem(NSMenuItem.separator())
        for d in AirBatteryModel.getAll() {
            let timePast = min(Int((now - d.lastUpdate) / 60), 99)
            let batteryColor = getPowerColor(d.batteryLevel, emoji: true)
            let main = NSMenuItem(title: "\(batteryColor) \(getMonoNum(d.batteryLevel))\(d.isCharging != 0 ? " ⚡︎ " : "﹪")  \(timePast > 10 ? "⚠︎ " : "")\(d.deviceName)", action: nil, keyEquivalent: "")
            let alte = NSMenuItem(title: "[\(timePast == 99 ? " >" : "↻")\(getMonoNum(timePast,count:2))" + " mins ago".local + "]  \(timePast > 10 ? "⚠︎ " : "")\(d.deviceName)", action: nil, keyEquivalent: "")
            alte.isAlternate = true
            alte.keyEquivalentModifierMask = .option
            
            let submenu = NSMenu()
            let subm = NSMenuItem(title: "Hide This".local, action: #selector(addToBlackList(_ :)), keyEquivalent: "")
            subm.representedObject = d.deviceName
            submenu.addItem(subm)
            main.submenu = submenu
            menu.addItem(main)
            menu.addItem(alte)
            menu.addItem(NSMenuItem.separator())
        }
        let submenu = NSMenu()
        let hidden = NSMenuItem(title: "Hidden Device...".local, action: #selector(blank), keyEquivalent: "")
        let blackList = (UserDefaults.standard.object(forKey: "blackList") ?? []) as! [String]
        for d in blackList {
            let hiddenDevice = NSMenuItem(title: d, action: #selector(removeFromBlackList(_ :)), keyEquivalent: "")
            hiddenDevice.representedObject = d
            submenu.addItem(hiddenDevice)
            submenu.addItem(NSMenuItem.separator())
        }
        hidden.submenu = submenu
        menu.addItem(hidden)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle:"Settings...".local, action: #selector(openSettingPanel), keyEquivalent: "")
        menu.addItem(withTitle:"About AirBattery".local, action: #selector(openAboutPanel), keyEquivalent: "")
        if !fromDock {
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle:"Quit AirBattery".local, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        }
    }
    
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        dockWindow.orderOut(nil)
        getMenu(fromDock: true)
        return menu
    }
}
