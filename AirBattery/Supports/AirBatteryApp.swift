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

let fd = FileManager.default
let ud = UserDefaults.standard
var updaterController: SPUStandardUpdaterController!
var statusBarItem: NSStatusItem!
var pinnedItems = [NSStatusItem]()
var netcastService: MultipeerService = MultipeerService(serviceType: "airbattery-nc")
let ncFolder = fd.urls(for: .libraryDirectory, in: .userDomainMask).first!.appendingPathComponent("Containers/\(AirBatteryModel.key)/Data/Documents/NearcastData")
let systemUUID = getMacDeviceUUID()
var dockWindow = AutoHideWindow()
var menuPopover = NSPopover()
let bleBattery = BLEBattery()
let btdBattery = BTDBattery()
var updateDelay = 1
var keepAliveActivity: NSObjectProtocol? = nil

@main
struct AirBatteryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // If you want to start the updater manually, pass false to startingUpdater and call .startUpdater() later
        // This is where you can also pass an updater delegate if you need one
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        registerNotificationCategory()
    }
    
    var body: some Scene {
        Settings {
            SettingsView()
                .background(
                    WindowAccessor(
                        onWindowOpen: { w in
                            if let w = w {
                                //w.level = .floating
                                w.titlebarSeparatorStyle = .none
                                guard let nsSplitView = findNSSplitVIew(view: w.contentView),
                                      let controller = nsSplitView.delegate as? NSSplitViewController else { return }
                                controller.splitViewItems.first?.canCollapse = false
                                controller.splitViewItems.first?.minimumThickness = 175
                                controller.splitViewItems.first?.maximumThickness = 175
                                w.orderFront(nil)
                            }
                        })
                )
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, UNUserNotificationCenterDelegate {
    //static let shared = AppDelegate()
    @AppStorage("showOn") var showOn = "sbar"
    @AppStorage("machineType") var machineType = "mac"
    @AppStorage("deviceName") var deviceName = "Mac"
    @AppStorage("ncGroupID") var ncGroupID = ""
    @AppStorage("nearCast") var nearCast = false
    @AppStorage("launchAtLogin") var launchAtLogin = false
    @AppStorage("intBattOnStatusBar") var intBattOnStatusBar = true
    @AppStorage("batteryPercent") var batteryPercent = "outside"
    @AppStorage("alertSound") var alertSound = true
    @AppStorage("readBTHID") var readBTHID = true
    @AppStorage("hideLevel") var hideLevel = 90
    @AppStorage("disappearTime") var disappearTime = 20
    @AppStorage("whitelistMode") var whitelistMode = false
    @AppStorage("iosBatteryStyle") var iosBatteryStyle = false
    @AppStorage("updateInterval") var updateInterval = 1
    @AppStorage("carouselMode") var carouselMode = true
    
    //加载旧版设置项
    @AppStorage("alertLevel") var alertLevel = 10
    @AppStorage("fullyLevel") var fullyLevel = 100
    
    //var statusMenu: NSMenu = NSMenu()
    var menu: NSMenu = NSMenu()
    var startTime = Date()
    let nc = NSWorkspace.shared.notificationCenter
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if response.actionIdentifier == "DELAY_30_MIN" {
            let deviceName = response.notification.request.content.userInfo["customInfo"] as? String ?? ""
            lowPowerNoteDelay[deviceName] = Date().timeIntervalSince1970 + 1800
        }
        completionHandler()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // 用户点击 Dock 图标时会调用这个方法
        if showOn == "sbar" || showOn == "none" {
            openSettingPanel()
            return false
        }
        if dockWindow.isVisible {
            dockWindow.orderOut(nil)
        } else {
            var allDevices = AirBatteryModel.getAll()
            let ibStatus = InternalBattery.status
            if ibStatus.hasBattery { allDevices.insert(ib2ab(ibStatus), at: 0) }
            let contentViewSwiftUI = popover(fromDock: true, allDevice: allDevices)
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
            let menuHeight = CGFloat((max(max(allDevices.count,1)+ncDeviceCount,1)+hiddenRow)*37+30+ncCount)
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
                    menuY = max(menuY - menuHeight/2, visibleFrame.origin.y)
                case "left":
                    // Dock 位于屏幕左侧
                    menuX = menuX + 352 > visibleFrame.maxX ? visibleFrame.maxX - 372 : menuX
                    menuX = menuX < visibleFrame.origin.x ? visibleFrame.origin.x + 20 : menuX + 10
                    menuY = max(menuY - menuHeight/2, visibleFrame.origin.y)
                default:
                    print("⚠️ Failed to get Dock orientation!")
                }
            }
            contentView.frame = NSRect(x: menuX, y: menuY, width: 352, height: menuHeight)
            dockWindow = AutoHideWindow(contentRect: contentView.frame, styleMask: [.fullSizeContentView], backing: .buffered, defer: false)
            dockWindow.title = "AirBattery Dock Window"
            dockWindow.level = .popUpMenu
            dockWindow.contentView = contentView
            dockWindow.isOpaque = false
            dockWindow.backgroundColor = NSColor.clear
            dockWindow.contentView?.wantsLayer = true
            dockWindow.contentView?.layer?.cornerRadius = 7
            dockWindow.contentView?.layer?.masksToBounds = true
            dockWindow.makeKeyAndOrderFront(nil)
        }
        return true
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        // default defaults (used if not set)
        ud.register(
            defaults: [
                "showOn": "sbar",
                "machineType": "mac",
                "deviceName": "Mac",
                "launchAtLogin": false,
                "intBattOnStatusBar": true,
                "deviceOnWidget": "",
                "updateInterval": 1,
                "widgetInterval": 0,
                "hideLevel": 90,
                "nearCast": false,
                "readBTHID": true,
                "whitelistMode": false,
                "neverRemindMe": [String]()
            ]
        )
        
        updateDelay = updateInterval
        machineType = getMacDeviceType()
        deviceName = getMacDeviceName()
        InternalBattery.status = getPowerState()
        
        if showOn == "dock" || showOn == "both" { NSApp.setActivationPolicy(.regular) }
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withTimeZone]
        menu.addItem(withTitle:"Settings...".local, action: #selector(openSetting), keyEquivalent: "")
        menu.addItem(withTitle:"About AirBattery".local, action: #selector(openAbout), keyEquivalent: "")
        
        //处理旧版偏好设置
        if let alertList = (ud.object(forKey: "alertList") ?? []) as? [String] {
            let alerts: [btAlert] = alertList.map({
                btAlert(name: $0, full: fullyLevel == 100 ? 99 : fullyLevel, fullOn: true, fullSound: alertSound, low: alertLevel, lowOn: true, lowSound: alertSound)
            })
            ud.set([], forKey: "alertList")
            ud.set(object: alerts, forKey: "alertList")
        }
        
        if !fd.fileExists(atPath: ncFolder.path) {
            do {
                try fd.createDirectory(at: ncFolder, withIntermediateDirectories: true, attributes: nil)
                print("ℹ️ Folder created at: \(ncFolder.path)")
            } catch {
                print("⚠️ Failed to create folder: \(error)")
            }
        } else {
            let oldFiles = getFiles(withExtension: "json", in: ncFolder)
            for url in oldFiles { try? fd.removeItem(at: url) }
        }
        
        startTime = Date()
        nc.addObserver(self, selector: #selector(onDisplayWake), name: NSWorkspace.screensDidWakeNotification, object: nil)
        IOBluetoothDevice.register(forConnectNotifications: self, selector: #selector(deviceIsConnected(notification:fromDevice:)))
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(handleURLEvent(_:replyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
        //if let window = NSApplication.shared.windows.first { window.close() }
        launchAtLogin = NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.lihaoyun6.AirBatteryHelper" }
        print("⚙️ Launch AirBattery at login = \(launchAtLogin)")
        print("⚙️ Icon mode = \(showOn)")
        if ncGroupID != "" { if nearCast { netcastService.resume() } }
        if let result = process(path: "/usr/sbin/system_profiler", arguments: ["SPBluetoothDataType", "-json"]) { SPBluetoothDataModel.shared.data = result }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error { print("⚠️ Notification authorization denied: \(error.localizedDescription)") }
        }
        UNUserNotificationCenter.current().delegate = self
        
        bleBattery.startScan()
        btdBattery.startScan()
        MagicBattery.shared.startScan()
        IDeviceBattery.shared.startScan()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            AirBatteryModel.writeData()
            _ = AirBatteryModel.singleDeviceName()
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        //menu.delegate = self
        //statusMenu.delegate = self
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        //statusBarItem.menu = statusMenu
        if let button = statusBarItem.button {
            button.target = self
            let ib = getPowerState()
            let iconView = NSHostingView(rootView: mainBatteryView())
            if ib.hasBattery && intBattOnStatusBar {
                iconView.frame = NSRect(x: 0, y: 0, width: 42, height: 21.5)
            } else {
                iconView.frame = NSRect(x: 0, y: 0, width: 36, height: 21.5)
            }
            button.image = NSImage()
            button.addSubview(iconView)
            button.frame = iconView.frame
            button.action = #selector(togglePopover(_ :))
        }
        statusBarItem.isVisible = !(showOn == "dock" || showOn == "none")
        NSApp.dockTile.contentView = NSHostingView(rootView: MultiBatteryView())
        NSApp.dockTile.display()
        if nearCast {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                netcastService.refeshAll()
            }
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let opts: ProcessInfo.ActivityOptions = [.automaticTerminationDisabled, .suddenTerminationDisabled]
        keepAliveActivity = ProcessInfo.processInfo.beginActivity(options: opts, reason: "AirBattery menu bar monitoring")

        if showOn == "dock" || showOn == "both" {
            let tipID = "ab.docktile-power.note"
            let never = ud.object(forKey: "neverRemindMe") as! [String]
            if !never.contains(tipID) {
                let alert = createAlert(title: "AirBattery Tips".local, message: "Displaying AirBattery on the Dock will consume more power, it is better to use Menu Bar mode or Widgets.".local, button1: "Don't remind me again", button2: "OK")
                if alert.runModal() == .alertFirstButtonReturn { ud.setValue(never + [tipID], forKey: "neverRemindMe") }
            }
        }
        
        if readBTHID {
            let tipID = "ab.third-party-device.note"
            let never = ud.object(forKey: "neverRemindMe") as! [String]
            if !never.contains(tipID) {
                let alert = createAlert(title: "AirBattery Tips".local, message: "If some of your devices shows battery level in the Bluetooth menu, but AirBattery doesn't find it. Try disconnecting and reconnecting it, and wait a few minutes.".local, button1: "Don't remind me again", button2: "OK")
                if alert.runModal() == .alertFirstButtonReturn { ud.setValue(never + [tipID], forKey: "neverRemindMe") }
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let act = keepAliveActivity { ProcessInfo.processInfo.endActivity(act) }

        _ = process(path: "/usr/bin/killall", arguments: ["idevicesyslog"])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
    
    @objc func onDisplayWake() {
        if readBTHID {
            DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
                BTDBattery.getOtherDevice(last: "2m", timeout: 2)
            }
        }
    }
    
    @objc func deviceIsConnected(notification: IOBluetoothUserNotification, fromDevice device: IOBluetoothDevice) {
        if readBTHID {
            let now = Date()
            if now.timeIntervalSince(startTime) >= 10 {
                if let name = device.name, let macAdd = device.addressString {
                    if AirBatteryModel.checkIfBlocked(name: name) { return }
                    //if let prefix = getFirstNCharacters(of: macAdd, count: 8) {
                        print("ℹ️ \(name) (\(macAdd)) connected")
                        DispatchQueue.global(qos: .background).async {
                            usleep(2500000)
                            //if !appleMacPrefix.contains(prefix) {
                            if !device.isAppleDevice {
                                SPBluetoothDataModel.shared.refeshData { _ in
                                    BTDBattery.getOtherDevice(last: "2m", timeout: 2)
                                    MagicBattery.shared.getIOBTBattery()
                                    MagicBattery.shared.getOtherBTBattery()
                                }
                            } else {
                                if let device = AirBatteryModel.getByName(name) {
                                    if ["Trackpad", "Keyboard", "MMouse", "Mouse"].contains(device.deviceType) {
                                        SPBluetoothDataModel.shared.refeshData { _ in MagicBattery.shared.scanDevices() }
                                    }
                                } else {
                                    SPBluetoothDataModel.shared.refeshData { _ in MagicBattery.shared.scanDevices() }
                                }
                            }
                        }
                    //}
                }
            }
        }
    }
    
    /*func menuWillOpen(_ menu: NSMenu) {
        dockWindow.orderOut(nil)
        var allDevices = AirBatteryModel.getAll()
        let ibStatus = InternalBattery.status
        if ibStatus.hasBattery { allDevices.insert(ib2ab(ibStatus), at: 0) }
        let contentViewSwiftUI = popover(fromDock: false, allDevice: allDevices)
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
        contentView.frame = NSRect(x: 0, y: 0, width: 352, height: (max(max(allDevices.count,1)+ncDeviceCount,1)+hiddenRow)*37+20+ncCount)
        let menuItem = NSMenuItem()
        menuItem.view = contentView
        statusMenu.removeAllItems()
        statusMenu.addItem(menuItem)
    }*/
    
    @objc func togglePopover(_ sender: Any?) {
        if let button = statusBarItem.button, !menuPopover.isShown {
            var allDevices = AirBatteryModel.getAll()
            let ibStatus = InternalBattery.status
            if ibStatus.hasBattery { allDevices.insert(ib2ab(ibStatus), at: 0) }
            let contentView = NSHostingController(rootView: popover(fromDock: false, allDevice: allDevices))
            menuPopover.setValue(true, forKeyPath: "shouldHideAnchor")
            menuPopover.contentViewController = contentView
            menuPopover.behavior = .transient
            var bound = button.bounds
            if getMenuBarHeight() == 24.0 { bound.origin.y -= 6 }
            menuPopover.show(relativeTo: bound, of: button, preferredEdge: .minY)
            //menuPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            menuPopover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        if let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
           let url = URL(string: urlString) {
            if url.scheme == "airbattery"{
                switch url.host {
                case "writedata" :
                    print("Writing data to disk...")
                    AirBatteryModel.writeData()
                case "reloadwingets" :
                    print("Reloading all widgets...")
                    AirBatteryModel.writeData()
                    WidgetCenter.shared.reloadAllTimelines()
                default: print("Unknow command!")
                }
            }
        }
    }
     
    @objc func openAbout() {
        openAboutPanel()
    }
    
    @objc func openSetting() {
        openSettingPanel()
    }
    
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        dockWindow.orderOut(nil)
        return menu
    }
}

class NNSWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
}

class AutoHideWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    override func resignKey() {
        super.resignKey()
        self.orderOut(nil)
    }
}

extension NSImage {
    func resized(to maxSize: NSSize) -> NSImage {
        let aspectWidth = maxSize.width / self.size.width
        let aspectHeight = maxSize.height / self.size.height
        let aspectRatio = min(aspectWidth, aspectHeight)
        
        let newSize = NSSize(width: self.size.width * aspectRatio, height: self.size.height * aspectRatio)
        
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        self.draw(in: NSRect(origin: .zero, size: newSize),
                  from: NSRect(origin: .zero, size: self.size),
                  operation: .sourceOver,
                  fraction: 1.0)
        newImage.unlockFocus()
        
        return newImage
    }
}

public extension UserDefaults {
    func set<T: Codable>(object: T, forKey: String) {
        if let jsonData = try? JSONEncoder().encode(object) {
            set(jsonData, forKey: forKey)
        }
    }
    
    func get<T: Codable>(objectType: T.Type, forKey: String) -> T? {
        guard let result = value(forKey: forKey) as? Data else {
            return nil
        }

        return try? JSONDecoder().decode(objectType, from: result)
    }
}

func refeshPinnedBar(unpin: String? = nil) {
    var pinnedList = (ud.object(forKey: "pinnedList") ?? []) as! [String]
    if pinnedList.isEmpty { return }
    if let unpin = unpin { pinnedList.removeAll(where: { $0 == unpin }) }
    var allDevices = AirBatteryModel.getAll()
    let ncFiles = getFiles(withExtension: "json", in: ncFolder)
    for ncFile in ncFiles { allDevices += AirBatteryModel.ncGetAll(url: ncFile) }
    let pinnedDevices = allDevices.filter({ pinnedList.contains($0.deviceName) })
    let deviceNames = pinnedDevices.map({ $0.deviceName })
    for device in pinnedDevices {
        if let index = pinnedItems.firstIndex(where: { $0.button?.toolTip == device.deviceName }) {
            pinnedItems[index].button?.title = "\(device.batteryLevel)\(device.isCharging != 0  ? "⚡︎" : "%")"
        } else {
            let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            if let button = statusItem.button {
                let icon = getDeviceIcon(device)
                let image = NSImage(named: icon)!.resized(to: NSSize(width: 17, height: 17))
                image.isTemplate = true
                button.image = image
                button.title = "\(device.batteryLevel)\(device.isCharging != 0  ? "⚡︎" : "%")"
                button.toolTip = device.deviceName
            }
            pinnedItems.append(statusItem)
        }
    }
    let expItems = pinnedItems.filter({ !pinnedList.contains($0.button?.toolTip ?? "") || !deviceNames.contains($0.button?.toolTip ?? "") })
    let expNames = expItems.map({ $0.button?.toolTip ?? "" })
    DispatchQueue.main.async { for e in expItems { NSStatusBar.system.removeStatusItem(e) } }
    pinnedItems.removeAll{ expNames.contains($0.button?.toolTip ?? "") }
}

@discardableResult
func ensureLoginItem(enabled: Bool) -> Bool {
    let helperBundleIdentifier = "com.lihaoyun6.AirBatteryHelper"
    if #available(macOS 13.0, *) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            NSLog("[AirBattery] SMAppService register/unregister failed: \(error.localizedDescription)")
            return false
        }
    } else {
        let ok = SMLoginItemSetEnabled(helperBundleIdentifier as CFString, enabled)
        if !ok { NSLog("[AirBattery] SMLoginItemSetEnabled failed for \(helperBundleIdentifier)") }
        return ok
    }
}

func registerDefaults() {
    UserDefaults.standard.register(defaults: ["LaunchAtLogin": false])
}
