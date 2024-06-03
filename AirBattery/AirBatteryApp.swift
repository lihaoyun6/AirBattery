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
import Sparkle

var updaterController: SPUStandardUpdaterController!
var statusBarItem: NSStatusItem!

@main
struct AirBatteryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // If you want to start the updater manually, pass false to startingUpdater and call .startUpdater() later
        // This is where you can also pass an updater delegate if you need one
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    static let shared = AppDelegate()
    @AppStorage("showOn") var showOn = "both"
    @AppStorage("machineType") var machineType = "Mac"
    @AppStorage("deviceName") var deviceName = "Mac"
    @AppStorage("launchAtLogin") var launchAtLogin = false
    @AppStorage("intBattOnStatusBar") var intBattOnStatusBar = true
    @AppStorage("statusBarBattPercent") var statusBarBattPercent = false
    @AppStorage("hidePercentWhenFull") var hidePercentWhenFull = false
    //var blackList = (UserDefaults.standard.object(forKey: "blackList") ?? []) as! [String]
    
    var statusMenu: NSMenu = NSMenu()
    var menu: NSMenu = NSMenu()
    var dockWindow = NSWindow()
    let bleBattery = BLEBattery()
    let magicBattery = MagicBattery()
    let ideviceBattery = IDeviceBattery()
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // 用户点击 Dock 图标时会调用这个方法
        if showOn == "sbar" {
            openSettingPanel()
            return false
        }
        if dockWindow.isVisible {
            dockWindow.orderOut(nil)
        } else {
            var allDevices = AirBatteryModel.getAll()
            let ibStatus = InternalBattery.status
            if ibStatus.hasBattery { allDevices.insert(ib2ab(ibStatus), at: 0) }
            let contentViewSwiftUI = popover(fromDock: true, allDevices: allDevices)
            let contentView = NSHostingView(rootView: contentViewSwiftUI)
            let hiddenRow = AirBatteryModel.getBlackList().count > 0 ? 1 : 0
            let mouse = NSEvent.mouseLocation
            var menuX = mouse.x
            var menuY = mouse.y
            if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) {
                let visibleFrame = screen.visibleFrame
                var dockOrientation = "bottom"
                if let defaults = UserDefaults(suiteName: "com.apple.dock"), let orientation = defaults.string(forKey: "orientation") { dockOrientation = orientation }
                switch dockOrientation {
                case "bottom":
                    // Dock 位于屏幕底部
                    menuX = menuX + 372 > visibleFrame.maxX ? visibleFrame.maxX : menuX - 176
                    menuY = max(menuY, visibleFrame.origin.y) + 20
                case "right":
                    // Dock 位于屏幕右侧
                    menuX = menuX + 352 > visibleFrame.maxX ? visibleFrame.maxX - 372 : menuX + 10
                    menuY = max(menuY - CGFloat((max(allDevices.count,1)+hiddenRow)*37+25)/2, visibleFrame.origin.y)
                case "left":
                    // Dock 位于屏幕左侧
                    menuX = menuX + 352 > visibleFrame.maxX ? visibleFrame.maxX - 372 : menuX
                    menuX = menuX < visibleFrame.origin.x ? visibleFrame.origin.x + 20 : menuX + 10
                    menuY = max(menuY - CGFloat((max(allDevices.count,1)+hiddenRow)*37+25)/2, visibleFrame.origin.y)
                default:
                    print("⚠️ Failed to get Dock orientation!")
                }
            }
            contentView.frame = NSRect(x: menuX, y: menuY, width: 352, height: CGFloat((max(allDevices.count,1)+hiddenRow)*37+25))
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
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        if showOn == "dock" || showOn == "both" { NSApp.setActivationPolicy(.regular) }
        UserDefaults.standard.register( // default defaults (used if not set)
            defaults: [
                "showOn": "both",
                "machineType": "Mac",
                "deviceName": "Mac",
                "launchAtLogin": false,
                "intBattOnStatusBar": true,
                "statusBarBattPercent": false,
                "hidePercentWhenFull": false,
                "deviceOnWidget": "@@@@@@@@@@@@@@@@@@@@"
            ]
        )
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        //if let window = NSApplication.shared.windows.first { window.close() }
        launchAtLogin = NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.lihaoyun6.AirBatteryHelper" }
        print("⚙️ Launch AirBattery at login = \(launchAtLogin)")
        
        machineType = getMacDeviceType()
        deviceName = getMacDeviceName()
        if let result = process(path: "/usr/sbin/system_profiler", arguments: ["SPBluetoothDataType", "-json"]) { SPBluetoothDataModel.data = result }
        AirBatteryModel.writeData()
        _ = AirBatteryModel.singleDeviceName()
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
                let iconView = NSHostingView(rootView: mainBatteryView())
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
        statusBarItem.isVisible = !(showOn == "dock" || showOn == "none")
        print("⚙️ Icon mode = \(showOn)")
        NSApp.dockTile.contentView = NSHostingView(rootView: MultiBatteryView())
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
        if ibStatus.hasBattery { allDevices.insert(ib2ab(ibStatus), at: 0) }
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
            let main = NSMenuItem(title: "\(batteryColor) \(getMonoNum(level))\(ibStatus.isCharging ? " ⚡︎ " : "﹪")  \(machineType)", action: #selector(blank), keyEquivalent: "")
            let alte = NSMenuItem(title: "[\(timeText)]  \(machineType)", action: nil, keyEquivalent: "")
            alte.isAlternate = true
            alte.keyEquivalentModifierMask = .option
            menu.addItem(main)
            menu.addItem(alte)
        } else {
            menu.addItem(withTitle: machineType, action: #selector(blank), keyEquivalent: "")
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
    
    func createAlert(level: NSAlert.Style = .warning, title: String, message: String, button1: String, button2: String = "") -> NSAlert {
        let alert = NSAlert()
        alert.messageText = title.local
        alert.informativeText = message.local
        alert.addButton(withTitle: button1.local)
        if button2 != "" { alert.addButton(withTitle: button2.local) }
        alert.alertStyle = level
        return alert
    }
}
