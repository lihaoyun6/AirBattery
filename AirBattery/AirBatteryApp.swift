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
import IOBluetooth
import Sparkle

var updaterController: SPUStandardUpdaterController!
var statusBarItem: NSStatusItem!
var netcastService: MultipeerService?
let ncFolder = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!.appendingPathComponent("Containers/\(AirBatteryModel.key)/Data/Documents/NearcastData")
let systemUUID = getMacDeviceUUID()

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
    @AppStorage("ncGroupID") var ncGroupID = ""
    @AppStorage("nearCast") var nearCast = false
    @AppStorage("launchAtLogin") var launchAtLogin = false
    @AppStorage("intBattOnStatusBar") var intBattOnStatusBar = true
    @AppStorage("statusBarBattPercent") var statusBarBattPercent = false
    @AppStorage("hidePercentWhenFull") var hidePercentWhenFull = false
    @AppStorage("readBTHID") var readBTHID = true
    //var blackList = (UserDefaults.standard.object(forKey: "blackList") ?? []) as! [String]
    
    var statusMenu: NSMenu = NSMenu()
    var menu: NSMenu = NSMenu()
    var dockWindow = NSWindow()
    var startTime = Date()
    let bleBattery = BLEBattery()
    let btdBattery = BTDBattery()
    let magicBattery = MagicBattery()
    let ideviceBattery = IDeviceBattery()
    let nc = NSWorkspace.shared.notificationCenter
    
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
            allDevices.insert(ib2ab(ibStatus), at: 0)
            let contentViewSwiftUI = popover(fromDock: true, allDevices: allDevices)
            let contentView = NSHostingView(rootView: contentViewSwiftUI)
            let hiddenRow = AirBatteryModel.getBlackList().count > 0 ? 1 : 0
            let allNearcast = getFiles(withExtension: "json", in: ncFolder)
            var ncCount = 0
            var ncDeviceCount = 0
            for jsonUrl in allNearcast {
                let count = AirBatteryModel.ncGetAll(url: jsonUrl).count
                if count != 0 {
                    ncCount += 7
                    ncDeviceCount += count
                }
            }
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
                    //menuX = menuX + 186 > visibleFrame.maxX ? visibleFrame.maxX - 362 : menuX - 176
                    if menuX + 186 > visibleFrame.maxX {
                        menuX = visibleFrame.maxX - 362
                    } else if menuX - 166 < visibleFrame.minX {
                        menuX = visibleFrame.minX + 10
                    } else {
                        menuX = menuX - 176
                    }
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
            contentView.frame = NSRect(x: menuX, y: menuY, width: 352, height: CGFloat((max(allDevices.count+ncDeviceCount,1)+hiddenRow)*37+30+ncCount))
            dockWindow = NSWindow(contentRect: contentView.frame, styleMask: [.fullSizeContentView], backing: .buffered, defer: false)
            dockWindow.title = "AirBattery Dock Window"
            dockWindow.level = .popUpMenu
            dockWindow.contentView = contentView
            dockWindow.isOpaque = false
            dockWindow.backgroundColor = NSColor.clear
            dockWindow.contentView?.wantsLayer = true
            dockWindow.contentView?.layer?.cornerRadius = 6
            dockWindow.contentView?.layer?.masksToBounds = true
            dockWindow.orderFront(self)
        }
        return true
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        if showOn == "dock" || showOn == "both" { NSApp.setActivationPolicy(.regular) }
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withTimeZone]
        menu.addItem(withTitle:"Settings...".local, action: #selector(openSettingPanel), keyEquivalent: "")
        menu.addItem(withTitle:"About AirBattery".local, action: #selector(openAboutPanel), keyEquivalent: "")
        UserDefaults.standard.register( // default defaults (used if not set)
            defaults: [
                "showOn": "both",
                "machineType": "Mac",
                "deviceName": "Mac",
                "launchAtLogin": false,
                "intBattOnStatusBar": true,
                "statusBarBattPercent": false,
                "hidePercentWhenFull": false,
                "deviceOnWidget": "",
                "updateInterval": 1.0,
                "widgetInterval": 0,
                "nearCast": false,
                "readBTHID": true,
                "neverRemindMe": [String]()
            ]
        )
        
        if !FileManager.default.fileExists(atPath: ncFolder.path) {
            do {
                try FileManager.default.createDirectory(at: ncFolder, withIntermediateDirectories: true, attributes: nil)
                print("ℹ️ Folder created at: \(ncFolder.path)")
            } catch {
                print("⚠️ Failed to create folder: \(error)")
            }
        } else {
            let oldFiles = getFiles(withExtension: "json", in: ncFolder)
            for url in oldFiles { try? FileManager.default.removeItem(at: url) }
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        startTime = Date()
        nc.addObserver(self, selector: #selector(onDisplayWake), name: NSWorkspace.screensDidWakeNotification, object: nil)
        IOBluetoothDevice.register(forConnectNotifications: self, selector: #selector(deviceIsConnected(notification:fromDevice:)))
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(handleURLEvent(_:replyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
        //if let window = NSApplication.shared.windows.first { window.close() }
        launchAtLogin = NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.lihaoyun6.AirBatteryHelper" }
        print("⚙️ Launch AirBattery at login = \(launchAtLogin)")
        print("⚙️ Icon mode = \(showOn)")
        if ncGroupID != "" {
            netcastService = MultipeerService(serviceType: String(ncGroupID.prefix(15)))
            if nearCast { netcastService?.resume() }
        }
        machineType = getMacDeviceType()
        deviceName = getMacDeviceName()
        if let result = process(path: "/usr/sbin/system_profiler", arguments: ["SPBluetoothDataType", "-json"]) { SPBluetoothDataModel.data = result }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error { print("⚠️ Notification authorization denied: \(error.localizedDescription)") }
        }
        
        bleBattery.startScan()
        btdBattery.startScan()
        magicBattery.startScan()
        ideviceBattery.startScan()
        
        if readBTHID {
            let tipID = "ab.third-party-device.note"
            let never = UserDefaults.standard.object(forKey: "neverRemindMe") as! [String]
            if !never.contains(tipID) {
                let alert = createAlert(title: "AirBattery Tips".local, message: "If some of your devices shows battery level in the Bluetooth menu, but AirBattery doesn't find it. Try disconnecting and reconnecting it, and wait a few minutes.".local, button1: "Don't remind me again", button2: "OK")
                if alert.runModal() == .alertFirstButtonReturn {
                    UserDefaults.standard.setValue(never + [tipID], forKey: "neverRemindMe")
                }
            }
            /*if !IOHIDRequestAccess(kIOHIDRequestTypeListenEvent) {
                let alert = createAlert(title: "Permission Required".local, message: "AirBattery does not log any of your input! This permission is only used to read battery info from HID devices.".local, button1: "Open Settings")
                if alert.runModal() == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!)
                }
            }*/
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            AirBatteryModel.writeData()
            _ = AirBatteryModel.singleDeviceName()
            WidgetCenter.shared.reloadAllTimelines()
        }
        
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
                let image = NSImage(named: "bolt.square.fill")!
                image.size = NSSize(width: 16, height: 16)
                button.image = image
            }
        }
        statusBarItem.isVisible = !(showOn == "dock" || showOn == "none")
        NSApp.dockTile.contentView = NSHostingView(rootView: MultiBatteryView())
        NSApp.dockTile.display()
    }
    
    func setStatusBar(width: Double) {
        let iconView = NSHostingView(rootView: mainBatteryView())
        iconView.frame = NSRect(x: 0, y: 0, width: width, height: 21.5)
        statusBarItem.button?.subviews.removeAll()
        statusBarItem.button?.addSubview(iconView)
        statusBarItem.button?.frame = iconView.frame
    }
    
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
    
    @objc func onDisplayWake() {
        if readBTHID {
            DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
                BTDBattery.getOtherDevice(last: "2m")
            }
        }
        //print("\(Date(timeIntervalSinceNow: 0)) -> Display wake")
    }
    
    @objc func deviceIsConnected(notification: IOBluetoothUserNotification, fromDevice device: IOBluetoothDevice) {
        let now = Date()
        if now.timeIntervalSince(startTime) >= 10 {
            if let name = device.name, let macAdd = device.addressString {
                print("ℹ️ \(name) (\(macAdd)) connected")
                DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                    BTDBattery.getOtherDevice(last: "2m")
                }
            }
        }
    }
    
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
        allDevices.insert(ib2ab(ibStatus), at: 0)
        let contentViewSwiftUI = popover(fromDock: false, allDevices: allDevices)
        let contentView = NSHostingView(rootView: contentViewSwiftUI)
        let hiddenRow = AirBatteryModel.getBlackList().count > 0 ? 1 : 0
        let allNearcast = getFiles(withExtension: "json", in: ncFolder)
        var ncCount = 0
        var ncDeviceCount = 0
        for jsonUrl in allNearcast {
            let count = AirBatteryModel.ncGetAll(url: jsonUrl).count
            if count != 0 {
                ncCount += 7
                ncDeviceCount += count
            }
        }
        contentView.frame = NSRect(x: 0, y: 0, width: 352, height: (max(allDevices.count+ncDeviceCount,1)+hiddenRow)*37+20+ncCount)
        let menuItem = NSMenuItem()
        menuItem.view = contentView
        statusMenu.removeAllItems()
        statusMenu.addItem(menuItem)
    }
    
    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        if let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
           let url = URL(string: urlString) {
            if url.scheme == "airbattery"{
                switch url.host {
                case "reloadwingets" :
                    print("Reloading all widgets...")
                    AirBatteryModel.writeData()
                    WidgetCenter.shared.reloadAllTimelines()
                default: print("Unknow command!")
                }
            }
        }
    }
     
    @objc func openAboutPanel() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }
    
    @objc func openSettingPanel() {
        dockWindow.orderOut(nil)
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14, *) {
            NSApp.mainMenu?.items.first?.submenu?.item(at: 2)?.performAction()
        }else if #available(macOS 13, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.windows.first(where: { $0.title == "AirBattery Settings".local })?.level = .floating
        }
    }
    
    /*func getMenu(fromDock: Bool = false) {
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
    }*/
    
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        dockWindow.orderOut(nil)
        return menu
    }
}
