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
    
    func updateNSView(_ nsView: NSView, context: NSViewRepresentableContext<Tooltip>) { }
}

struct WindowConfigurator: NSViewRepresentable {
    var onWindowConfigured: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()

        DispatchQueue.main.async {
            if let window = view.window {
                self.onWindowConfigured(window)
            } else {
                self.onWindowConfigured(nil)
            }
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

public extension View {
    func toolTip(_ toolTip: String) -> some View {
        self.overlay(Tooltip(tooltip: toolTip))
    }
}

struct SettingsView: View {
    @State private var selectedItem: String? = "General"
    @State private var showDebug: Bool = false
    
    var body: some View {
        NavigationView {
            List(selection: $selectedItem) {
                NavigationLink(destination: GeneralView(showDebug: $showDebug), tag: "General", selection: $selectedItem) {
                    Label("General", image: "gear")
                }
                NavigationLink(destination: NearbilityView(), tag: "Nearbility", selection: $selectedItem) {
                    Label("Nearbility", image: "nearbility")
                }
                NavigationLink(destination: NearcastView(), tag: "Nearcast", selection: $selectedItem) {
                    Label("Nearcast", image: "nearcast")
                }
                NavigationLink(destination: DisplayView(), tag: "Display", selection: $selectedItem) {
                    Label("Menu Bar & Dock", image: "dock")
                }
                NavigationLink(destination: WidgetView(), tag: "Widget", selection: $selectedItem) {
                    Label("Widget", image: "widget")
                }
                NavigationLink(destination: BlacklistView(), tag: "Blacklist", selection: $selectedItem) {
                    Label("Blacklist", image: "blacklist")
                }
                if showDebug {
                    NavigationLink(destination: DebugView(), tag: "Debug", selection: $selectedItem) {
                        Label("Debug", image: "debug")
                    }
                }
            }
            .listStyle(.sidebar)
            .padding(.top, 9)
        }
        .frame(width: 600, height: 430)
        .navigationTitle("AirBattery Settings")
        //.background(WindowConfigurator { window in window?.level = .floating })
    }
}

struct SField: View {
    var title: LocalizedStringKey
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
            Spacer()
            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 220)
        }
    }
}

struct SPicker<T: Hashable, Content: View, Style: PickerStyle>: View {
    var title: LocalizedStringKey
    @Binding var selection: T
    var style: Style
    var tips: LocalizedStringKey?
    @ViewBuilder let content: () -> Content
    
    @State private var isPresented: Bool = false
    
    init(_ title: LocalizedStringKey, selection: Binding<T>, style: Style = .menu, tips: LocalizedStringKey? = nil, @ViewBuilder content: @escaping () -> Content) {
            self.title = title
            self._selection = selection
            self.style = style
            self.tips = tips
            self.content = content
        }
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if let tips = tips {
                Button(action: {
                    isPresented = true
                }, label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 15, weight: .light))
                        .opacity(0.5)
                })
                .buttonStyle(.plain)
                .padding(.trailing, -10)
                .sheet(isPresented: $isPresented) {
                    VStack(alignment: .trailing) {
                        GroupBox { Text(tips).padding() }
                        Button(action: {
                            isPresented = false
                        }, label: {
                            Text("OK").frame(width: 30)
                        }).keyboardShortcut(.defaultAction)
                    }.padding()
                }
            }
            Picker("", selection: $selection) { content() }
                .fixedSize()
                .pickerStyle(style)
                .buttonStyle(.borderless)
        }.frame(height: 16)
    }
}

struct SToggle: View {
    var title: LocalizedStringKey
    @Binding var isOn: Bool
    var tips: LocalizedStringKey?
    
    @State private var isPresented: Bool = false
    
    init(_ title: LocalizedStringKey, isOn: Binding<Bool>, tips: LocalizedStringKey? = nil) {
        self.title = title
        self._isOn = isOn
        self.tips = tips
    }
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if let tips = tips {
                Button(action: {
                    isPresented = true
                }, label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 15, weight: .light))
                        .opacity(0.5)
                })
                .buttonStyle(.plain)
                .sheet(isPresented: $isPresented) {
                    VStack(alignment: .trailing) {
                        GroupBox { Text(tips).padding() }
                        Button(action: {
                            isPresented = false
                        }, label: {
                            Text("OK").frame(width: 30)
                        }).keyboardShortcut(.defaultAction)
                    }.padding()
                }
            }
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .scaleEffect(0.7)
                .frame(width: 32)
        }.frame(height: 16)
    }
}

struct SSteper: View {
    var title: LocalizedStringKey
    @Binding var value: Int
    var tips: LocalizedStringKey?
    var length: CGFloat
    var min: Int
    var max: Int
    
    @State private var isPresented: Bool = false
    
    init(_ title: LocalizedStringKey, value: Binding<Int>, tips: LocalizedStringKey? = nil, length: CGFloat = 45, min: Int = 0, max: Int = 100) {
        self.title = title
        self._value = value
        self.tips = tips
        self.length = length
        self.min = min
        self.max = max
    }
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if let tips = tips {
                Button(action: {
                    isPresented = true
                }, label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 15, weight: .light))
                        .opacity(0.5)
                })
                .buttonStyle(.plain)
                .sheet(isPresented: $isPresented) {
                    VStack(alignment: .trailing) {
                        GroupBox { Text(tips).padding() }
                        Button(action: {
                            isPresented = false
                        }, label: {
                            Text("OK").frame(width: 30)
                        }).keyboardShortcut(.defaultAction)
                    }.padding()
                }
            }
            TextField("", value: $value, formatter: NumberFormatter())
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: length)
                .onChange(of: value) { newValue in
                    if newValue > max { value = max }
                    if newValue < min { value = min }
                }
            Stepper("", value: $value)
                .padding(.leading, -10)
        }.frame(height: 16)
    }
}

struct GeneralView: View {
    @AppStorage("showOn") var showOn = "sbar"
    @AppStorage("launchAtLogin") var launchAtLogin = false
    
    @Binding var showDebug: Bool
    @State private var debugCount: Int = 0

    var body: some View {
        VStack(spacing: 30) {
            GroupBox(label: Text("Startup").font(.headline)) {
                VStack(spacing: 10) {
                    SToggle("Launch at Login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { newValue in
                            SMLoginItemSetEnabled("com.lihaoyun6.AirBatteryHelper" as CFString, newValue)
                        }
                    Divider().opacity(0.5)
                    SPicker("Show AirBattery", selection: $showOn) {
                        Text("Dock").tag("dock")
                        Text("Menu Bar").tag("sbar")
                        Text("Both").tag("both")
                        Text("None").tag("none")
                    }.onChange(of: showOn) { newValue in
                        switch newValue {
                        case "sbar":
                            statusBarItem.isVisible = true
                            for i in pinnedItems { i.isVisible = true }
                            NSApp.setActivationPolicy(.accessory)
                        case "both":
                            statusBarItem.isVisible = true
                            for i in pinnedItems { i.isVisible = true }
                            NSApp.setActivationPolicy(.regular)
                        case "dock":
                            statusBarItem.isVisible = false
                            for i in pinnedItems { i.isVisible = false }
                            NSApp.setActivationPolicy(.regular)
                        default:
                            statusBarItem.isVisible = false
                            for i in pinnedItems { i.isVisible = false }
                            NSApp.setActivationPolicy(.accessory)
                        }
                        if newValue == "dock" || newValue == "both" {
                            _ = createAlert(title: "AirBattery Tips".local, message: "Displaying AirBattery on the Dock will consume more power, it is better to use Menu Bar mode or Widgets.".local, button1: "OK").runModal()
                        }
                    }
                }.padding(5)
            }
            GroupBox(label: Text("Update").font(.headline)) {
                VStack(spacing: 10) {
                    UpdaterSettingsView(updater: updaterController.updater)
                }.padding(5)
            }
            VStack(spacing: 8) {
                CheckForUpdatesView(updater: updaterController.updater)
                if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("AirBattery v\(appVersion)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .onTapGesture {
                            debugCount += 1
                            if debugCount > 10 {
                                debugCount = 0
                                showDebug.toggle()
                            }
                        }
                }
            }
            Spacer().frame(minHeight: 0)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct NearbilityView: View {
    @AppStorage("ideviceOverBLE") var ideviceOverBLE = false
    @AppStorage("readBTDevice") var readBTDevice = true
    @AppStorage("readBLEDevice") var readBLEDevice = false
    @AppStorage("readPencil") var readPencil = false
    @AppStorage("readIDevice") var readIDevice = true
    @AppStorage("readBTHID") var readBTHID = true
    @AppStorage("updateInterval") var updateInterval = 1
    @AppStorage("twsMerge") var twsMerge = 5
    
    var body: some View {
        VStack(spacing: 30) {
            GroupBox(label: Text("Scanner").font(.headline)) {
                VStack(spacing: 10) {
                    SToggle("Discover iOS devices via Network", isOn: $readIDevice, tips: "Scan your iPhone / iPad / Apple Watch / VisionPro and other iDevices in your local network.")
                    Divider().opacity(0.5)
                    SToggle("Discover iOS devices via Bluetooth", isOn: $ideviceOverBLE, tips: "Scan your iPhone and iPad (Cellular) via Bluetooth.")
                    Divider().opacity(0.5)
                    SToggle("Discover BT and BLE devices", isOn: $readBTDevice, tips: "Get the battery usage of some Bluetooth peripherals like mouse, keyboard, headphone or etc.\n\nIf some of your device is not shown, try enabling \"Discover more BT devices\" or \"Discover more BLE devices\"")
                    Divider().opacity(0.5)
                    SToggle("Discover more BT devices", isOn: $readBTHID, tips: "Get the battery usage of more third-party Bluetooth devices\n\nBattery data will be updated when devices are reconnected to the Mac or the Mac wakes up.")
                    Divider().opacity(0.5)
                    SToggle("Discover more BLE devices", isOn: $readBLEDevice, tips: "Try to get the battery usage of any Bluetooth device that AirBattery can find\n\nWARNING: This is a BETA feature and may cause unexpected errors!")
                        .foregroundColor(.orange)
                        .onChange(of: readBLEDevice) { newValue in
                            if newValue {
                                _ = createAlert(title: "AirBattery Tips".local, message: "If you see a bluetooth pairing request from any device that isn't yours, add it to your blacklist!".local, button1: "OK").runModal()
                            }
                        }
                    Divider().opacity(0.5)
                    SToggle("Apple Pencil from your iPad", isOn: $readPencil, tips: "Read the battery status of the connected Apple Pencil through your iPad\n(It may take 10 minutes or longer to discover the Pencil for the first time)\n\nWARNING: This is a BETA feature and may drain your iPad's battery faster!")
                        .foregroundColor(.orange)
                }.padding(5)
            }
            GroupBox(label: Text("Others").font(.headline)) {
                VStack(spacing: 10) {
                    VStack(spacing: 2) {
                        SSteper("Refresh Interval (min)", value: $updateInterval, min: 1, max: 99)
                        if updateDelay != updateInterval {
                            HStack {
                                Text("Relaunch AirBattery to apply this change")
                                    .font(.footnote)
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                    Divider().opacity(0.5)
                    SSteper("Earbud Merging Threshold", value: $twsMerge, min: 1, max: 99)
                }.padding(5)
            }
            Spacer().frame(minHeight: 0)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct NearcastView: View {
    @AppStorage("nearCast") var nearCast = false
    @AppStorage("ncGroupID") var ncGroupID = ""
    @State var debug: Bool = false

    var body: some View {
        VStack(spacing: 30) {
            GroupBox(label: Text("Nearcast").font(.headline)) {
                VStack(spacing: 10) {
                    SToggle("Enable Nearcast", isOn: $nearCast)
                        .onChange(of: nearCast) { newValue in
                            if newValue {
                                if ncGroupID != "" && isGroudIDValid(id: ncGroupID) {
                                    netcastService.resume()
                                } else {
                                    DispatchQueue.main.async { nearCast = false; ncGroupID = "" }
                                    _ = createAlert(
                                        title: "Invalid group ID".local,
                                        message: "Please create or enter a valid Group ID before use!",
                                        button1: "OK".local
                                    ).runModal()
                                }
                            } else {
                                netcastService.stop()
                            }
                        }
                    Divider().opacity(0.5)
                    HStack(spacing: 4) {
                        SField(title: "Group ID", text: $ncGroupID).disabled(nearCast)
                        Button(action: {
                            ncGroupID = "nc-" + randomString(length: 20)
                        }, label: {
                            if ncGroupID != "" {
                                Image(systemName: "arrow.clockwise.circle")
                                    .font(.system(size: 15, weight: .light))
                            } else {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 15, weight: .light))
                            }
                        })
                        .buttonStyle(.plain)
                        .disabled(nearCast)
                        Button(action: {
                            if ncGroupID != "" && isGroudIDValid(id: ncGroupID) {
                                copyToClipboard(ncGroupID)
                                _ = createAlert(title: "Group ID Copied".local,
                                                message: String(format: "Group ID has been copied to the clipboard.".local, ncGroupID),
                                                button1: "OK".local).runModal()
                            } else {
                                DispatchQueue.main.async { ncGroupID = "" }
                                _ = createAlert(
                                    title: "Invalid group ID".local,
                                    message: "Please create or enter a valid Group ID before use!",
                                    button1: "OK".local
                                ).runModal()
                            }
                        }, label: {
                            Image("list.clipboard.fill.circle")
                                .resizable().scaledToFit()
                                .frame(width: 15, height: 15)
                        }).buttonStyle(.plain)
                    }.frame(height: 16)
                    Divider().opacity(0.5)
                    VStack(spacing: 2) {
                        Text("Nearcast will broadcast your battery data within the local network.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Text("Your data has been encrypted using the group id, don't share it with others.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }.padding(5)
            }
            GroupBox(label: Text("Peer Info").font(.headline)) {
                VStack(spacing: 10) {
                    HStack {
                        Text("Local ID")
                        Spacer()
                        Text(netcastService.transceiver.localPeerId ?? "")
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundColor(.secondary)
                    }
                }.padding(5)
            }
            Spacer().frame(minHeight: 0)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct DisplayView: View {
    @AppStorage("appearance") var appearance = "auto"
    @AppStorage("showThisMac") var showThisMac = "icon"
    @AppStorage("carouselMode") var carouselMode = true
    @AppStorage("colorfulBattery") var colorfulBattery = false
    @AppStorage("iosBatteryStyle") var iosBatteryStyle = false
    @AppStorage("intBattOnStatusBar") var intBattOnStatusBar = true
    @AppStorage("batteryPercent") var batteryPercent = "outside"
    @AppStorage("hideLevel") var hideLevel = 90
    @State private var levelList = [95, 90, 80, 70, 60, 50, 40, 30, 20, 10]
    
    var body: some View {
        VStack(spacing: 30) {
            GroupBox(label: Text("Menu Bar").font(.headline)) {
                VStack(spacing: 10) {
                    SToggle("Dynamic Battery Icon", isOn: $intBattOnStatusBar)
                    Divider().opacity(0.5)
                    SToggle("Colorful Battery Icon", isOn: $colorfulBattery)
                        .disabled(!intBattOnStatusBar)
                    Divider().opacity(0.5)
                    SPicker("Battery Icon Style", selection: $iosBatteryStyle) {
                        Text("macOS").tag(false)
                        Text("iOS").tag(true)
                    }.disabled(!intBattOnStatusBar)
                    Divider().opacity(0.5)
                    SPicker("Show Percentage", selection: $batteryPercent) {
                        Text("Hidden").tag("hide")
                        Text("Inside").tag("inside")
                        Text("Outside").tag("outside")
                    }.disabled(!intBattOnStatusBar)
                    Divider().opacity(0.5)
                    SPicker("Hide percentage when above", selection: $hideLevel) {
                        Text("Never").tag(100)
                        ForEach(levelList, id: \.self) { number in
                            Text("\(number)%").tag(number)
                        }
                        if !levelList.contains(hideLevel) && hideLevel != 100 {
                            Text("\(hideLevel)%").tag(hideLevel)
                        }
                    }.disabled(!intBattOnStatusBar || (batteryPercent == "hide"))
                }.padding(5)
            }
            GroupBox(label: Text("Dock").font(.headline)) {
                VStack(spacing: 10) {
                    SPicker("Appearance", selection: $appearance) {
                        Text("Automatic").tag("auto")
                        Text("Light").tag("false")
                        Text("Dark").tag("true")
                    }.pickerStyle(.segmented)
                    Divider().opacity(0.5)
                    SPicker("Built-in Battery Style", selection: $showThisMac, tips: "Show or hide this Mac's built-in battery in the Dock icon") {
                        Text("Hidden").tag("hidden")
                        Text("Device Icon").tag("icon")
                        Text("Percent").tag("percent")
                    }
                    Divider().opacity(0.5)
                    SToggle("Carousel Mode", isOn: $carouselMode, tips: "Cycle through all found devices in the Dock icon")
                }.padding(5)
            }
            Spacer().frame(minHeight: 0)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct WidgetView: View {
    @AppStorage("showMacOnWidget") var showMacOnWidget = true
    @AppStorage("revListOnWidget") var revListOnWidget = false
    @AppStorage("deviceOnWidget") var deviceOnWidget = ""
    @AppStorage("widgetInterval") var widgetInterval = 0
    @AppStorage("deviceName") var deviceName = "Mac"
    
    @State var ib = getMacDeviceType().lowercased().contains("book")
    @State var devices = [String]()

    var body: some View {
        VStack(spacing: 30) {
            GroupBox(label: Text("Widget").font(.headline)) {
                VStack(spacing: 10) {
                    SToggle("Show Built-in Battery", isOn: $showMacOnWidget)
                    Divider().opacity(0.5)
                    SToggle("Reverse Device List", isOn: $revListOnWidget)
                    Divider().opacity(0.5)
                    SPicker("Refresh Interval", selection: $widgetInterval) {
                        Text("System Default").tag(-1)
                        Text("Same as Nearbility").tag(0)
                    }
                    if #unavailable(macOS 14) {
                        Divider().opacity(0.5)
                        SPicker("Single Device Widget", selection: $deviceOnWidget) {
                            Text("Not Set").tag("")
                            if ib { Text(deviceName).tag(deviceName) }
                            ForEach(devices, id: \.self) { device in
                                Text(device).tag(device)
                            }
                            if !devices.contains(deviceOnWidget) && deviceOnWidget != deviceName && deviceOnWidget != "" {
                                Text(deviceOnWidget).tag(deviceOnWidget)
                            }
                        }.onChange(of: deviceOnWidget) { _ in _ = AirBatteryModel.singleDeviceName() }
                    }
                    Divider().opacity(0.5)
                    HStack {
                        Spacer()
                        Button(action: {
                            AirBatteryModel.writeData()
                            WidgetCenter.shared.reloadAllTimelines()
                        }, label: {
                            Text("Reload All Widgets")
                        })
                    }
                }.padding(5)
            }
            Spacer().frame(minHeight: 0)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .onAppear { devices = AirBatteryModel.getAll(noFilter: true).filter({ $0.hasBattery }).map({ $0.deviceName }) }
        .onReceive(dockTimer) { _ in
            if #unavailable(macOS 14) {
                devices = AirBatteryModel.getAll(noFilter: true).filter({ $0.hasBattery }).map({ $0.deviceName })
            }
        }
    }
}

struct BlacklistView: View {
    @AppStorage("whitelistMode") var whitelistMode = false
    @State private var blockedItems = [String]()
    @State private var temp = ""
    @State private var showSheet = false
    @State private var editingIndex: Int?
    
    var body: some View {
        VStack(spacing: 30) {
            GroupBox(label: Text("Blacklist").font(.headline)) {
                VStack(spacing: 10) {
                    SToggle("Whitelist Mode", isOn: $whitelistMode)
                    Divider().opacity(0.5)
                    HStack {
                        Spacer()
                        Text(whitelistMode ? "Only the following devices will be showed" : "The following devices will be ignored")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    ZStack(alignment: Alignment(horizontal: .trailing, vertical: .bottom)) {
                        List {
                            ForEach(0..<blockedItems.count, id: \.self) { index in
                                HStack {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red)
                                        .onTapGesture { if editingIndex == nil { blockedItems.remove(at: index) } }
                                    Text(blockedItems[index])
                                }
                            }
                        }
                        Button(action: {
                            showSheet = true
                        }) {
                            Image(systemName: "plus.square.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showSheet){
                            VStack {
                                TextField("Enter Device Name".local, text: $temp).frame(width: 300)
                                HStack(spacing: 20) {
                                    Button {
                                        if temp == "" { return }
                                        if !blockedItems.contains(temp) { blockedItems.append(temp) }
                                        temp = ""
                                        showSheet = false
                                    } label: {
                                        Text("Add to List").frame(width: 80)
                                    }.keyboardShortcut(.defaultAction)
                                    Button {
                                        showSheet = false
                                    } label: {
                                        Text("Cancel").frame(width: 80)
                                    }
                                }.padding(.top, 10)
                            }.padding()
                        }
                    }
                }.padding(5)
            }
            .onAppear { blockedItems = (ud.object(forKey: "blockedDevices") as? [String]) ?? [String]() }
            .onChange(of: blockedItems) { b in ud.setValue(b, forKey: "blockedDevices") }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct DebugView: View {
    @AppStorage("test_debug") var test_debug = false
    @AppStorage("test_hasib") var test_hasib = false
    @AppStorage("test_acpower") var test_ac = false
    @AppStorage("test_full") var test_full = false
    @AppStorage("test_iblevel") var test_iblevel = 100
    
    @State private var deviceID: String = ""
    @State private var deviceType: String = ""
    @State private var deviceName: String = ""
    @State private var deviceModel: String = ""
    @State private var parentName: String = ""
    @State private var batteryLevel: Int = 0
    @State private var lowPower: Bool = false
    @State private var isCharging: Bool = false
    @State private var fullCharged: Bool = false
    
    
    
    @State private var isPresented: Bool = false
    
    var body: some View {
        VStack(spacing: 30) {
            GroupBox {
                VStack(spacing: 10) {
                    SToggle("Debug Mode", isOn: $test_debug)
                    Divider().opacity(0.5)
                    HStack {
                        Text("Data Folder")
                        Spacer()
                        Button("Open") {
                            NSWorkspace.shared.open(ncFolder.deletingLastPathComponent())
                        }
                    }
                }.padding(5)
            }
            GroupBox(label: Text("Built-in Battery").font(.headline)) {
                VStack(spacing: 10) {
                    SToggle("Built-in Battery", isOn: $test_hasib)
                    Divider().opacity(0.5)
                    SToggle("AC Powered", isOn: $test_ac)
                    Divider().opacity(0.5)
                    SToggle("Paused", isOn: $test_full)
                    Divider().opacity(0.5)
                    SSteper("Level", value: $test_iblevel, min: 1)
                }.padding(5)
            }
            GroupBox(label: Text("Remote Battery").font(.headline)) {
                VStack(spacing: 10) {
                    HStack {
                        Text("Create Item")
                        Spacer()
                        Button(action: {
                            isPresented = true
                        }, label: {
                            Image(systemName: "plus.circle.fill")
                        })
                        .buttonStyle(.plain)
                        .sheet(isPresented: $isPresented) {
                            VStack {
                                GroupBox(label: Text("Remote Battery").font(.headline)) {
                                    VStack(spacing: 10) {
                                        SField(title: "Device ID", text: $deviceID)
                                        Divider().opacity(0.5)
                                        SField(title: "Device Name", text: $deviceName)
                                        Divider().opacity(0.5)
                                        SField(title: "Device Type", text: $deviceType)
                                        Divider().opacity(0.5)
                                        SField(title: "Device Model", text: $deviceModel)
                                        Divider().opacity(0.5)
                                        HStack {
                                            SField(title: "Parent Name", text: $parentName)
                                            Button(action: {
                                                parentName = getMacDeviceName()
                                            }, label: {
                                                let ib = ib2ab(InternalBattery.status)
                                                Image(getDeviceIcon(ib))
                                                    .resizable().scaledToFit()
                                                    .frame(width: 16, height: 16)
                                            }).buttonStyle(.plain)
                                        }
                                        Divider().opacity(0.5)
                                        SSteper("Level", value: $batteryLevel)
                                        Divider().opacity(0.5)
                                        SToggle("Charging", isOn: $isCharging)
                                        Divider().opacity(0.5)
                                        SToggle("Paused", isOn: $fullCharged)
                                        Divider().opacity(0.5)
                                        SToggle("Low Power", isOn: $lowPower)
                                    }.padding(5)
                                }
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        isPresented = false
                                    }, label: {
                                        Text("Cancle").frame(width: 50)
                                    })
                                    Button(action: {
                                        let device = Device(deviceID: deviceID, deviceType: deviceType, deviceName: deviceName, batteryLevel: batteryLevel, isCharging: isCharging ? 1 : (fullCharged ? 5 : 0), lowPower: lowPower, parentName: parentName,lastUpdate: Date().timeIntervalSince1970)
                                        AirBatteryModel.updateDevice(device)
                                        isPresented = false
                                    }, label: {
                                        Text("Add").frame(width: 50)
                                    }).keyboardShortcut(.defaultAction)
                                }
                            }
                            .padding()
                            .onAppear {
                                deviceID = randomString(length: 10)
                                deviceType = ""
                                deviceName = ""
                                deviceModel = ""
                                parentName = ""
                                batteryLevel = 0
                                lowPower = false
                                isCharging = false
                                fullCharged = false
                            }
                        }
                    }
                }.padding(5)
            }
            Spacer().frame(minHeight: 0)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}
