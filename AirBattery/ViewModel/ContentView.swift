//
//  ContentView.swift
//  AirBattery
//
//  Created by apple on 2023/9/4.
//
import AppKit
import SwiftUI
import WidgetKit
import Combine
//import UserNotifications

/*let test_data: [CGFloat] = [99,80,80,73,70,60,59,51,30,30,25,25,19,18,17,15,12,10,10,9] // 示例数据
struct BarChartView: View {
    let data: [CGFloat] // 电量数据，取值范围 0 到 1
    let barSpacing: CGFloat // 柱子之间的间距
    let barWidth: CGFloat // 柱子宽度

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: barSpacing) { // 设置底部对齐
                ForEach(0..<data.count, id: \.self) { index in
                    let height = (data[index] * geometry.size.height)/100
                    Capsule()
                        .fill(Color(getPowerColor(Int(data[index]))))
                        .frame(width: barWidth, height: height)
                        .padding(.bottom, -barWidth / 2) // 设置底部平坦
                }
            }
        }
    }
}*/

class AppearanceMonitor: ObservableObject {
    @Published var isDarkMode: Bool = false
    private var appearanceChangeCancellable: AnyCancellable?

    init() {
        updateAppearance()
        appearanceChangeCancellable = NotificationCenter.default.publisher(for: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateAppearance()
            }
    }
    private func updateAppearance() {
        let appearance = NSApp.effectiveAppearance
        isDarkMode = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
}

struct MultiBatteryView: View {
    @AppStorage("showThisMac") var showThisMac = "icon"
    @AppStorage("carouselMode") var carouselMode = true
    @AppStorage("appearance") var appearance = "auto"
    @AppStorage("showOn") var showOn = "sbar"
    @AppStorage("widgetInterval") var widgetInterval = 0
    @AppStorage("readBTHID") var readBTHID = true
    @AppStorage("deviceName") var deviceName = "Mac"
    @AppStorage("nearCast") var nearCast = false
    @AppStorage("ncGroupID") var ncGroupID = ""
    
    @StateObject private var appearanceMonitor = AppearanceMonitor()

    @State private var rollCount = 1
    @State private var darkMode = getDarkMode()
    @State private var lastTime = Double(Date().timeIntervalSince1970)
    @State private var batteryList = AirBatteryModel.getAll()
    @State private var lineWidth = 6.0
    
    var body: some View {
        ZStack {
            Group{
                Image(darkMode ? "background_dark" : "background")
                RoundedRectangle(cornerRadius: 23.5, style: RoundedCornerStyle.continuous)
                    .strokeBorder(darkMode ? .white : .black, lineWidth: 2)
                    .frame(width: 104, height: 104)
                    .opacity(darkMode ? 0.25 : 0.0)
                RoundedRectangle(cornerRadius: 23.5, style: RoundedCornerStyle.continuous)
                    .strokeBorder(.black, lineWidth: 1)
                    .frame(width: 104, height: 104)
                    .opacity(darkMode ? 0.55 : 0.2)
            }
            if batteryList.count < 4 {
                Circle()
                    .trim(from: 0.0, to: 0.75)
                    .stroke(style: StrokeStyle(lineWidth: lineWidth*1.2, lineCap: .round, lineJoin: .round))
                    .foregroundColor(darkMode ? .white : .black)
                    .opacity(darkMode ? 0.2 : 0.13)
                    .rotationEffect(Angle(degrees: 135))
                    .offset(x:-24, y: -24)
                    .frame(width: 38, height: 38, alignment: .center)
            } else {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        ForEach(batteryList[0..<2], id: \.self) { item in
                            ZStack {
                                Group {
                                    Group {
                                        Circle()
                                            .trim(from: 0.0, to: 0.75)
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth*1.2, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(darkMode ? .white : .black)
                                            .opacity(darkMode ? 0.2 : 0.13)
                                        Circle()
                                            .trim(from: CGFloat(abs((min(Double(item.batteryLevel)/100.0*0.75, 0.75))-0.001)), to: CGFloat(abs((min(Double(item.batteryLevel)/100.0*0.75, 0.75))-0.0005)))
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(Color(getPowerColor(item)))
                                            .shadow(color: .black, radius: lineWidth*0.76, x: 0, y: 0)
                                            .clipShape(
                                                Circle()
                                                    .trim(from: 0.0, to: 0.75)
                                                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            )
                                            .opacity(item.batteryLevel == 100 ? 0 : 1)
                                        Circle()
                                            .trim(from: 0.0, to: Double(item.batteryLevel)/100.0*0.75)
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(Color(getPowerColor(item)))
                                    }.rotationEffect(Angle(degrees: 135))
                                    
                                    if item.deviceType.contains("mac") && showThisMac == "percent"{
                                        Text(String(item.batteryLevel))
                                            .colorScheme(darkMode ? .dark : .light)
                                            .foregroundColor(item.isCharging != 0 ? Color("dark_"+getPowerColor(item)) : Color("black_white"))
                                            .font(.custom("Helvetica-Bold", size: item.batteryLevel>99 ? 32 : 42))
                                            .frame(width: 100, alignment: .center)
                                            .scaleEffect(0.5)
                                            .offset(x:-0.2, y:1.5)
                                        
                                    } else {
                                        Image(getDeviceIcon(item))
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .colorScheme(darkMode ? .dark : .light)
                                            .foregroundColor(item.isCharging != 0 ? Color("dark_"+getPowerColor(item)) : Color("black_white"))
                                            .offset(y:-1)
                                            .frame(width: 44, height: 43, alignment: .center)
                                            .scaleEffect(0.5)
                                    }
                                }.frame(width: 38, height: 38, alignment: .center)
                                Text(item.hasBattery ? "\(item.batteryLevel)" : "")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(darkMode ? .white : .black)
                                    .scaleEffect(0.5)
                                    .offset(y: 17)
                            }
                        }
                    }
                    HStack(spacing: 10) {
                        ForEach(batteryList[2..<4], id: \.self) { item in
                            ZStack {
                                Group {
                                    Group {
                                        Circle()
                                            .trim(from: 0.0, to: 0.75)
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth*1.2, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(darkMode ? .white : .black)
                                            .opacity(darkMode ? 0.2 : 0.13)
                                        Circle()
                                            .trim(from: CGFloat(abs((min(Double(item.batteryLevel)/100.0*0.75, 0.75))-0.001)), to: CGFloat(abs((min(Double(item.batteryLevel)/100.0*0.75, 0.75))-0.0005)))
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(Color(getPowerColor(item)))
                                            .shadow(color: .black, radius: lineWidth*0.76, x: 0, y: 0)
                                            .clipShape(
                                                Circle()
                                                    .trim(from: 0.0, to: 0.75)
                                                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            )
                                            .opacity(item.batteryLevel == 100 ? 0 : 1)
                                        Circle()
                                            .trim(from: 0.0, to: Double(item.batteryLevel)/100.0*0.75)
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(Color(getPowerColor(item)))
                                    }.rotationEffect(Angle(degrees: 135))
                                    Image(getDeviceIcon(item))
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .colorScheme(darkMode ? .dark : .light)
                                        .foregroundColor(item.isCharging != 0 ? Color("dark_"+getPowerColor(item)) : Color("black_white"))
                                        .offset(y:-1)
                                        .frame(width: 44, height: 43, alignment: .center)
                                        .scaleEffect(0.5)
                                }.frame(width: 38, height: 38, alignment: .center)
                                Text(item.hasBattery ? "\(item.batteryLevel)" : "")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(darkMode ? .white : .black)
                                    .scaleEffect(0.5)
                                    .offset(y: 17)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 128, height: 128, alignment: .center)
        .onChange(of: appearanceMonitor.isDarkMode) { newValue in
            darkMode = newValue
            NSApp.dockTile.display()
        }
        .onChange(of: appearance) { _ in
            darkMode = getDarkMode()
            NSApp.dockTile.display()
        }
        .onReceive(alertTimer) {_ in batteryAlert() }
        .onReceive(widgetViewTimer) {_ in
            if widgetInterval != -1 { WidgetCenter.shared.reloadAllTimelines() }
        }
        .onReceive(dockTimer) {_ in IDeviceBattery.shared.scanDevices() }
        .onReceive(widgetDataTimer) {_ in
            SPBluetoothDataModel.shared.refeshData { result in
                DispatchQueue.global(qos: .background).async {
                    MagicBattery.shared.scanDevices()
                }
            }
        }
        .onReceive(nearCastTimer) {_ in
            if nearCast && ncGroupID != ""{
                var allDevices = AirBatteryModel.getAll()
                allDevices.insert(ib2ab(InternalBattery.status), at: 0)
                do {
                    let jsonData = try JSONEncoder().encode(allDevices)
                    guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
                    guard let data = encryptString(jsonString, password: ncGroupID) else { return }
                    let message = NCMessage(id: String(ncGroupID.prefix(15)), sender: systemUUID ?? deviceName, command: "", content: data)
                    netcastService.sendMessage(message)
                } catch {
                    print("Write JSON error：\(error)")
                }
            }
        }
        .onReceive(dockTimer) { t in
            if showOn == "both" || showOn == "dock" {
                var list = AirBatteryModel.getAll()
                let ncFiles = getFiles(withExtension: "json", in: ncFolder)
                for ncFile in ncFiles { list += AirBatteryModel.ncGetAll(url: ncFile) }
                let ibStatus = InternalBattery.status
                let now = Double(t.timeIntervalSince1970)
                
                if !carouselMode { rollCount = 1 }
                if ibStatus.hasBattery && showThisMac != "hidden" { list.insert(ib2ab(ibStatus), at: 0) }
                
                batteryList = sliceList(data: list, length: 4, count: rollCount)
                if batteryList == []{
                    rollCount = 1
                    batteryList = sliceList(data: list, length: 4, count: rollCount)
                }
                
                if now - lastTime >= 20 && list.count > 4 && carouselMode {
                    lastTime = now
                    rollCount = rollCount + 1
                }
                NSApp.dockTile.display()
            }
        }
    }
}

struct BlurView: NSViewRepresentable {
    
    private let material: NSVisualEffectView.Material
    
    init(material: NSVisualEffectView.Material) {
        self.material = material
    }
    
    func makeNSView(context: Context) -> some NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        nsView.material = material
    }
}

struct popover: View {
    var fromDock: Bool = false
    var allDevice: [Device]
    let hiddenDevices = AirBatteryModel.getBlackList()

    @AppStorage("nearCast") var nearCast = false
    
    @State private var allDevices = [Device]()
    @State private var overReloadButton = false
    @State private var overCopyButton = false
    @State private var overHideButton = false
    @State private var overAlertButton = false
    @State private var overPinButton = false
    @State private var overInfoButton = false
    @State private var overQuitButton = false
    @State private var overSettButton = false
    @State private var overReloButton = false
    @State private var overStack = -1
    @State private var overStack2 = -1
    @State private var overStackNC = -1
    @State private var hidden:[Int] = []
    @State private var hidden2:[Int] = []
    @State private var alertList = ud.get(objectType: [btAlert].self, forKey: "alertList") ?? []
    @State private var pinnedList = (ud.object(forKey: "pinnedList") ?? []) as! [String]
    @State private var allNearcast = getFiles(withExtension: "json", in: ncFolder)
    
    var body: some View {
        ZStack{
            if fromDock { Color.clear.background(BlurView(material: .menu)) }
            VStack(spacing: 0){
                if !fromDock {
                    Color.clear
                        .frame(height: 8.5)
                        .onHover { hovering in
                            if hovering {
                                overStack = -1
                                overStack2 = -1
                                overStackNC = -1
                            }
                        }
                }
                HStack(spacing: 4){
                    if !fromDock {
                        Button(action: {
                            NSApp.terminate(self)
                        }, label: {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 14, weight: .light))
                                .frame(width: 14, height: 14, alignment: .center)
                                .foregroundColor(overQuitButton ? .red : .secondary)
                                .opacity(overQuitButton ? 1 : 0.7)
                        })
                        .focusable(false)
                        .buttonStyle(PlainButtonStyle())
                        .onHover{ hovering in overQuitButton = hovering }
                    } else {
                        Button(action: {
                            dockWindow.orderOut(nil)
                        }, label: {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 14, weight: .light))
                                .frame(width: 14, height: 14, alignment: .center)
                                .foregroundColor(overQuitButton ? Color("my_yellow") : .secondary)
                                .opacity(overQuitButton ? 1 : 0.7)
                        })
                        .focusable(false)
                        .buttonStyle(PlainButtonStyle())
                        .onHover{ hovering in overQuitButton = hovering }
                    }
                    
                    Button(action: {
                        dockWindow.orderOut(nil)
                        statusBarItem.menu?.cancelTracking()
                        openAboutPanel()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                            NSApp.activate(ignoringOtherApps: true)
                        }
                    }, label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14, weight: .light))
                            .frame(width: 14, height: 14, alignment: .center)
                            .foregroundColor(overInfoButton ? .accentColor : .secondary)
                            .opacity(overInfoButton ? 1 : 0.7)
                    })
                    .focusable(false)
                    .buttonStyle(PlainButtonStyle())
                    .onHover{ hovering in overInfoButton = hovering }
                    Button(action: {
                        dockWindow.orderOut(nil)
                        statusBarItem.menu?.cancelTracking()
                        openSettingPanel()
                    }, label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13.6, weight: .light))
                            .frame(width: 14, height: 14, alignment: .center)
                            .foregroundColor(overSettButton ? .accentColor : .secondary)
                            .opacity(overSettButton ? 1 : 0.7)
                    })
                    .focusable(false)
                    .buttonStyle(PlainButtonStyle())
                    .onHover{ hovering in overSettButton = hovering }
                    Spacer()
                    if nearCast {
                        Button(action: {
                            netcastService.refeshAll()
                            if fromDock {
                                dockWindow.orderOut(nil)
                            } else {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    allDevices = AirBatteryModel.getAll()
                                    let ibStatus = InternalBattery.status
                                    if ibStatus.hasBattery { allDevices.insert(ib2ab(ibStatus), at: 0) }
                                    allNearcast = getFiles(withExtension: "json", in: ncFolder)
                                }
                            }
                        }, label: {
                            Image(systemName: "antenna.radiowaves.left.and.right.circle")
                                .font(.system(size: 14, weight: .light))
                                .frame(width: 14, height: 14, alignment: .center)
                                .foregroundColor(overReloButton ? .accentColor : .secondary)
                                .opacity(overReloButton ? 1 : 0.7)
                        })
                        .focusable(false)
                        .buttonStyle(PlainButtonStyle())
                        .onHover{ hovering in overReloButton = hovering }
                    }
                }
                .offset(y: -3.5)
                .padding(.horizontal, 5)
                .onHover{ hovering in (overStack, overStack2) = (-1, -1) }
                VStack(alignment:.leading,spacing: 0) {
                    if allDevices.count < 1 && hiddenDevices.count < 1{
                        HStack{
                            /*Image(systemName: "exclamationmark.circle")
                             .resizable()
                             .aspectRatio(contentMode: .fit)
                             .foregroundColor(Color("black_white"))
                             .frame(width: 20, height: 20, alignment: .center)
                             Text("No Device Found!")
                             .font(.system(size: 12))
                             .foregroundColor(Color("black_white"))
                             .frame(height: 24, alignment: .center)
                             .padding(.horizontal, 8)*/
                            let ib = ib2ab(InternalBattery.status)
                            Image(getDeviceIcon(ib))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(Color("black_white"))
                                .frame(width: 22, height: 22, alignment: .center)
                            Text("\(ib.deviceName)")
                                .font(.system(size: 12))
                                .foregroundColor(Color("black_white"))
                                .frame(height: 24, alignment: .center)
                                .padding(.horizontal, 7)
                            Spacer()
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 11)
                        .onHover{ hovering in
                            overStack2 = -1
                            overStackNC = -1
                            if hovering { overStack = 0 }
                        }
                        .background(overStack == 0 ? Color("black_white").opacity(0.15) : .clear)
                        if hiddenDevices.count > 0 { Divider() }
                    }
                    ForEach(allDevices.indices, id: \.self) { index in
                        VStack(spacing: 0){
                            if hidden.contains(index) {
                                HStack{
                                    Image("blank")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 24, alignment: .center)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 10)
                                    Spacer()
                                }
                            }else{
                                HStack {
                                    Image(getDeviceIcon(allDevices[index]))
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(Color("black_white"))
                                        .frame(width: 22, height: 22, alignment: .center)
                                    HStack(spacing: 1) {
                                        Text("\(((Date().timeIntervalSince1970 - allDevices[index].lastUpdate) / 60) > 10 ? "⚠︎ " : "")\(allDevices[index].deviceName)")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color("black_white"))
                                            .frame(height: 24, alignment: .center)
                                        Spacer().frame(width: 0.5)
                                        if alertList.map({$0.name}).contains(allDevices[index].deviceName) {
                                            Image(systemName: "bell.fill")
                                                .font(.system(size: 10))
                                                .foregroundColor(Color("black_white"))
                                        }
                                        if pinnedList.contains(allDevices[index].deviceName) {
                                            Image(systemName: "pin.fill")
                                                .font(.system(size: 10))
                                                .foregroundColor(Color("black_white"))
                                                .offset(y: 0.2)
                                        }
                                    }.padding(.horizontal, 7)
                                    Spacer()
                                    if allDevices[index].hasBattery {
                                        if overStack == index {
                                            HStack(spacing: 3) {
                                                if allDevices[index].deviceID == "@MacInternalBattery" {
                                                    Text(allDevices[index].isCharging != 0 ? "Until Full:" : "Until Empty:")
                                                        .font(.system(size: 11, weight: .medium))
                                                        .foregroundColor(.secondary)
                                                    Text(InternalBattery.status.timeLeft)
                                                        .font(.system(size: 11, weight: .medium))
                                                        .foregroundColor(.secondary)
                                                } else {
                                                    if allDevices[index].realUpdate != 0.0 {
                                                        Text("\(Int((Date().timeIntervalSince1970 - allDevices[index].realUpdate) / 60))"+" mins ago".local)
                                                            .font(.system(size: 11, weight: .medium))
                                                            .foregroundColor(.secondary)
                                                    } else {
                                                        Text("\(Int((Date().timeIntervalSince1970 - allDevices[index].lastUpdate) / 60))"+" mins ago".local)
                                                            .font(.system(size: 11, weight: .medium))
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                                Spacer().frame(width: 1)
                                                if !alertList.map({$0.name}).contains(allDevices[index].deviceName) {
                                                    Button(action: {
                                                        let alert = btAlert(name: allDevices[index].deviceName,
                                                                                    full: 80, fullOn: true, fullSound: true,
                                                                                    low: 20, lowOn: true, lowSound: true)
                                                        let alertWindowController = AlertWindowController()
                                                        alertWindowController.showAlert(with: alert, iconName: getDeviceIcon(allDevices[index]), onConfirm: { newAlert in
                                                            alertList = ud.get(objectType: [btAlert].self, forKey: "alertList") ?? []
                                                            alertList.append(newAlert)
                                                            ud.set(object: alertList, forKey: "alertList")
                                                        }, onCancel: {})
                                                    }, label: {
                                                        Image("bell.circle")
                                                            .resizable().scaledToFit()
                                                            .frame(width: 18, height: 18, alignment: .center)
                                                            .foregroundColor(overAlertButton ? .accentColor : .secondary)
                                                    })
                                                    .buttonStyle(PlainButtonStyle())
                                                    .onHover{ hovering in overAlertButton = hovering }
                                                } else {
                                                    Button(action: {
                                                        alertList = ud.get(objectType: [btAlert].self, forKey: "alertList") ?? []
                                                        if let alert = alertList.first(where: {$0.name == allDevices[index].deviceName}) {
                                                            let alertWindowController = AlertWindowController()
                                                            alertWindowController.showAlert(with: alert, iconName: getDeviceIcon(allDevices[index]), onConfirm: { newAlert in
                                                                alertList = ud.get(objectType: [btAlert].self, forKey: "alertList") ?? []
                                                                alertList.removeAll {$0.name == allDevices[index].deviceName}
                                                                alertList.append(newAlert)
                                                                ud.set(object: alertList, forKey: "alertList")
                                                            }, onCancel: {})
                                                        }
                                                    }, label: {
                                                        Image("bell.circle.fill")
                                                            .resizable().scaledToFit()
                                                            .frame(width: 18, height: 18, alignment: .center)
                                                            .foregroundColor(overAlertButton ? .accentColor : .secondary)
                                                    })
                                                    .buttonStyle(PlainButtonStyle())
                                                    .onHover{ hovering in overAlertButton = hovering }
                                                }
                                                if allDevices[index].deviceID != "@MacInternalBattery" {
                                                    if !pinnedList.contains(allDevices[index].deviceName) {
                                                        Button(action: {
                                                            pinnedList = (ud.object(forKey: "pinnedList") ?? []) as! [String]
                                                            pinnedList.append(allDevices[index].deviceName)
                                                            ud.set(pinnedList, forKey: "pinnedList")
                                                            refeshPinnedBar()
                                                        }, label: {
                                                            Image("pin.circle")
                                                                .resizable().scaledToFit()
                                                                .frame(width: 18, height: 18, alignment: .center)
                                                                .foregroundColor(overPinButton ? .accentColor : .secondary)
                                                        })
                                                        .buttonStyle(PlainButtonStyle())
                                                        .onHover{ hovering in overPinButton = hovering }
                                                    } else {
                                                        Button(action: {
                                                            pinnedList = (ud.object(forKey: "pinnedList") ?? []) as! [String]
                                                            pinnedList.removeAll(where:  { $0 == allDevices[index].deviceName })
                                                            ud.set(pinnedList, forKey: "pinnedList")
                                                            refeshPinnedBar()
                                                        }, label: {
                                                            Image("pin.circle.fill")
                                                                .resizable().scaledToFit()
                                                                .frame(width: 18, height: 18, alignment: .center)
                                                                .foregroundColor(overPinButton ? .accentColor : .secondary)
                                                        })
                                                        .buttonStyle(PlainButtonStyle())
                                                        .onHover{ hovering in overPinButton = hovering }
                                                    }
                                                }
                                                if #available(macOS 14, *) {
                                                    Button(action: {
                                                        copyToClipboard(allDevices[index].deviceName)
                                                        _ = createAlert(title: "Device Name Copied".local,
                                                                        message: String(format: "Device name \"%@\" has been copied to the clipboard.".local, allDevices[index].deviceName),
                                                                        button1: "OK".local).runModal()
                                                    }, label: {
                                                        Image("list.clipboard.fill.circle")
                                                            .resizable().scaledToFit()
                                                            .frame(width: 18, height: 18, alignment: .center)
                                                            .foregroundColor(overCopyButton ? .accentColor : .secondary)
                                                    })
                                                    .buttonStyle(PlainButtonStyle())
                                                    .onHover{ hovering in overCopyButton = hovering }
                                                }
                                                
                                                if allDevices[index].deviceID != "@MacInternalBattery" {
                                                    Button(action: {
                                                        hidden.append(index)
                                                        var blackList = (ud.object(forKey: "blackList") ?? []) as! [String]
                                                        blackList.append(allDevices[index].deviceName)
                                                        ud.set(blackList, forKey: "blackList")
                                                    }, label: {
                                                        Image("eye.slash.circle")
                                                            .resizable().scaledToFit()
                                                            .frame(width: 18, height: 18, alignment: .center)
                                                            .foregroundColor(overHideButton ? .accentColor : .secondary)
                                                    })
                                                    .buttonStyle(PlainButtonStyle())
                                                    .onHover{ hovering in overHideButton = hovering }
                                                }
                                            }
                                        } else {
                                            Text("\(allDevices[index].batteryLevel)%")
                                                .foregroundColor((allDevices[index].batteryLevel <= 10) ? Color("dark_my_red") : .primary)
                                                .font(.system(size: 11))
                                            BatteryView(item: allDevices[index])
                                                .scaleEffect(0.85)
                                        }
                                    }
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(overStack == index ? Color("black_white").opacity(0.15) : .clear)//.cornerRadius(4)
                                .clipShape(RoundedCornersShape(radius: 2.9, corners: index == allDevices.count - (hiddenDevices.count > 0 ? 0 : 1) ? [.bottomLeft, .bottomRight] : (index == 0 ? [.topLeft, .topRight] : [])))
                                .onHover{ hovering in
                                    overStack2 = -1
                                    overStackNC = -1
                                    if overStack != index { overStack = index }
                                }
                                /*.contextMenu{
                                    if nearCast && ["Trackpad", "Keyboard", "Mouse", "MMouse"].contains(allDevices[index].deviceType) {
                                        Section(header: Text("Transmit to...").textCase(nil)) {
                                            Divider()
                                            ForEach(netcastService.transceiver.availablePeers, id: \.self) { peer in
                                                Button (action:{
                                                    createNotification(title: "Transmitting".local,
                                                                       message: String(format: "%@ -> %@".local, allDevices[index].deviceName, peer.name),
                                                                       interval: 1)
                                                    if fromDock {
                                                        dockWindow.orderOut(nil)
                                                    } else {
                                                        menuPopover.performClose(nil)
                                                    }
                                                    DispatchQueue.global(qos: .background).async {
                                                        let ret = BTTool.disconnect(mac: allDevices[index].deviceID)
                                                        if ret {
                                                            netcastService.transDevice(device: allDevices[index], to: peer.name)
                                                        } else {
                                                            createNotification(title: "Transmission Failed".local,
                                                                               message: String(format: "Failed to disconnect %@!".local, allDevices[index].deviceName))
                                                        }
                                                    }
                                                }, label:{ Text(peer.name)})
                                            }
                                            if netcastService.transceiver.availablePeers.isEmpty { Text("No Available Peers".local) }
                                        }
                                    }
                                    if allDevices[index].deviceID != "@MacInternalBattery" {
                                        if !pinnedList.contains(allDevices[index].deviceName) {
                                            Button(action: {
                                                pinnedList = (ud.object(forKey: "pinnedList") ?? []) as! [String]
                                                pinnedList.append(allDevices[index].deviceName)
                                                ud.set(pinnedList, forKey: "pinnedList")
                                                refeshPinnedBar()
                                            }) {
                                                Label("Pin to Menu Bar", systemImage: "")
                                            }
                                        } else {
                                            Button(action: {
                                                pinnedList = (ud.object(forKey: "pinnedList") ?? []) as! [String]
                                                pinnedList.removeAll { $0 == allDevices[index].deviceName }
                                                ud.set(pinnedList, forKey: "pinnedList")
                                                refeshPinnedBar()
                                            }) {
                                                Label("Unpin This Device", systemImage: "")
                                            }
                                        }
                                        Divider()
                                        Menu(content: {
                                        }, label: {
                                            Label("Transfer to...", systemImage: "")
                                        })
                                        Divider()
                                        if #available(macOS 14, *) {
                                            Button(action: {
                                                copyToClipboard(allDevices[index].deviceName)
                                                _ = createAlert(title: "Device Name Copied".local,
                                                                message: String(format: "Device name: \"%@\" has been copied to the clipboard.".local, allDevices[index].deviceName),
                                                                button1: "OK".local).runModal()
                                            }) {
                                                Label("Copy Device Name", systemImage: "")
                                            }
                                        }
                                        Button(action: {
                                            hidden.append(index)
                                            var blackList = (ud.object(forKey: "blackList") ?? []) as! [String]
                                            blackList.append(allDevices[index].deviceName)
                                            ud.set(blackList, forKey: "blackList")
                                        }) {
                                            Label("Hide From List", systemImage: "")
                                        }
                                    }
                                }*/
                            }
                            if index != allDevices.count-1 { Divider() }
                        }
                    }
                    if hiddenDevices.count > 0 {
                        if allDevices.count > 0 { Divider() }
                        HStack(spacing: 5){
                            Image("sunglasses.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(Color("black_white"))
                                .frame(width: 22, height: 22, alignment: .center)
                                .padding(.vertical, 6)
                            Text("Hidden Device:")
                                .font(.system(size: 12))
                                .foregroundColor(Color("black_white"))
                                .frame(height: 24, alignment: .center)
                                .padding(.horizontal, 10)
                            Spacer()
                            ForEach(hiddenDevices.indices, id: \.self) { index in
                                if !hidden2.contains(index){
                                    Button(action: {
                                        hidden2.append(index)
                                        var blackList = (ud.object(forKey: "blackList") ?? []) as! [String]
                                        blackList.removeAll { $0 == hiddenDevices[index].deviceName }
                                        ud.set(blackList, forKey: "blackList")
                                    }, label: {
                                        Image(getDeviceIcon(hiddenDevices[index]))
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 20, height: 20, alignment: .center)
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 4)
                                            .background(overStack2 == index ? Color("black_white").opacity(0.15) : .clear).cornerRadius(2.5)
                                            .onHover{ hovering in
                                                overStack = -1
                                                overStackNC = -1
                                                if overStack2 != index { overStack2 = index }
                                            }
                                    })
                                    .buttonStyle(PlainButtonStyle())
                                    .help(hiddenDevices[index].deviceName)
                                }
                            }
                        }
                        .padding(.vertical, 1)
                        .padding(.horizontal, 10)
                        .onHover{ hovering in overStack = -1 }
                    }
                }
                .padding(.horizontal, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(Color.secondary, lineWidth: 1)
                        .padding(.vertical, -1)
                        .padding(.horizontal, 5)
                        .opacity(0.23)
                )
                .offset(y: 2.5)
                if nearCast {
                    ForEach(allNearcast.indices, id: \.self) { index in
                        let devices = AirBatteryModel.ncGetAll(url: allNearcast[index])
                        if devices.count != 0 {
                            nearcastView(devices: devices, mainIndex: index, overStackNC: $overStackNC)
                                .onHover{ hovering in
                                    overStack = -1
                                    overStack2 = -1
                                }
                        }
                    }
                }
                if !fromDock {
                    Color.clear
                        .frame(height: 8.5)
                        .onHover { hovering in
                            if hovering {
                                overStack = -1
                                overStack2 = -1
                                overStackNC = -1
                            }
                        }
                }
            }
        }
        .frame(width: 352)
        .onAppear { allDevices = allDevice }
        .onReceive(mainTimer) { t in
            if !fromDock && menuPopover.isShown {
                allDevices = AirBatteryModel.getAll()
                let ibStatus = InternalBattery.status
                if ibStatus.hasBattery { allDevices.insert(ib2ab(ibStatus), at: 0) }
                if nearCast { allNearcast = getFiles(withExtension: "json", in: ncFolder) }
            }
        }
    }
}

struct nearcastView: View {
    var devices: [Device]
    var mainIndex: Int
    @Binding var overStackNC: Int
    @State private var overStack = -1
    @State private var overCopyButton = false
    @State private var overAlertButton = false
    @State private var overPinButton = false
    @State private var alertList = ud.get(objectType: [btAlert].self, forKey: "alertList") ?? []
    @State private var pinnedList = (ud.object(forKey: "pinnedList") ?? []) as! [String]
    
    var body: some View {
        Spacer().frame(height: 8)
        VStack(spacing: 0){
            ForEach(devices.indices, id: \.self) { index in
                VStack(spacing: 0){
                    HStack {
                        Image(getDeviceIcon(devices[index]))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(Color("black_white"))
                            .frame(width: 22, height: 22, alignment: .center)
                        HStack(spacing: 1) {
                            Text("\(((Date().timeIntervalSince1970 - devices[index].lastUpdate) / 60) > 10 ? "⚠︎ " : "")\(devices[index].deviceName)")
                                .font(.system(size: 12))
                                .foregroundColor(Color("black_white"))
                                .frame(height: 24, alignment: .center)
                                .padding(.horizontal, 7)
                            Spacer().frame(width: 0.5)
                            if alertList.map({$0.name}).contains(devices[index].deviceName) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color("black_white"))
                            }
                            if pinnedList.contains(devices[index].deviceName) {
                                Image(systemName: "pin.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color("black_white"))
                                    .offset(y: 0.2)
                            }
                        }.padding(.horizontal, 7)
                        if overStackNC == mainIndex && overStack == index {
                            Spacer()
                            HStack(spacing: 3) {
                                Text("\(Int((Date().timeIntervalSince1970 - devices[index].lastUpdate) / 60))"+" mins ago".local)
                                    .font(.system(size: 11))
                                if devices[index].hasBattery {
                                    Spacer().frame(width: 1)
                                    if !alertList.map({$0.name}).contains(devices[index].deviceName) {
                                        Button(action: {
                                            let alert = btAlert(name: devices[index].deviceName,
                                                                full: 80, fullOn: true, fullSound: true,
                                                                low: 20, lowOn: true, lowSound: true)
                                            let alertWindowController = AlertWindowController()
                                            alertWindowController.showAlert(with: alert, iconName: getDeviceIcon(devices[index]), onConfirm: { newAlert in
                                                alertList = ud.get(objectType: [btAlert].self, forKey: "alertList") ?? []
                                                alertList.append(newAlert)
                                                ud.set(object: alertList, forKey: "alertList")
                                            }, onCancel: {})
                                        }, label: {
                                            Image("bell.circle")
                                                .resizable().scaledToFit()
                                                .frame(width: 18, height: 18, alignment: .center)
                                                .foregroundColor(overAlertButton ? .accentColor : .secondary)
                                        })
                                        .buttonStyle(PlainButtonStyle())
                                        .onHover{ hovering in overAlertButton = hovering }
                                    } else {
                                        Button(action: {
                                            alertList = ud.get(objectType: [btAlert].self, forKey: "alertList") ?? []
                                            if let alert = alertList.first(where: {$0.name == devices[index].deviceName}) {
                                                let alertWindowController = AlertWindowController()
                                                alertWindowController.showAlert(with: alert, iconName: getDeviceIcon(devices[index]), onConfirm: { newAlert in
                                                    alertList = ud.get(objectType: [btAlert].self, forKey: "alertList") ?? []
                                                    alertList.removeAll(where: {$0.name == devices[index].deviceName})
                                                    alertList.append(newAlert)
                                                    ud.set(object: alertList, forKey: "alertList")
                                                }, onCancel: {})
                                            }
                                        }, label: {
                                            Image("bell.circle.fill")
                                                .resizable().scaledToFit()
                                                .frame(width: 18, height: 18, alignment: .center)
                                                .foregroundColor(overAlertButton ? .accentColor : .secondary)
                                        })
                                        .buttonStyle(PlainButtonStyle())
                                        .onHover{ hovering in overAlertButton = hovering }
                                    }
                                    if !pinnedList.contains(devices[index].deviceName) {
                                        Button(action: {
                                            pinnedList = (ud.object(forKey: "pinnedList") ?? []) as! [String]
                                            pinnedList.append(devices[index].deviceName)
                                            ud.set(pinnedList, forKey: "pinnedList")
                                            refeshPinnedBar()
                                        }, label: {
                                            Image("pin.circle")
                                                .resizable().scaledToFit()
                                                .frame(width: 18, height: 18, alignment: .center)
                                                .foregroundColor(overPinButton ? .accentColor : .secondary)
                                        })
                                        .buttonStyle(PlainButtonStyle())
                                        .onHover{ hovering in overPinButton = hovering }
                                    } else {
                                        Button(action: {
                                            pinnedList = (ud.object(forKey: "pinnedList") ?? []) as! [String]
                                            pinnedList.removeAll { $0 == devices[index].deviceName }
                                            ud.set(pinnedList, forKey: "pinnedList")
                                            refeshPinnedBar()
                                        }, label: {
                                            Image("pin.circle.fill")
                                                .resizable().scaledToFit()
                                                .frame(width: 18, height: 18, alignment: .center)
                                                .foregroundColor(overPinButton ? .accentColor : .secondary)
                                        })
                                        .buttonStyle(PlainButtonStyle())
                                        .onHover{ hovering in overPinButton = hovering }
                                    }
                                    if #available(macOS 14, *) {
                                        Button(action: {
                                            copyToClipboard(devices[index].deviceName)
                                            _ = createAlert(title: "Device Name Copied".local,
                                                            message: String(format: "Device name \"%@\" has been copied to the clipboard.".local, devices[index].deviceName),
                                                            button1: "OK".local).runModal()
                                        }, label: {
                                            Image("list.clipboard.fill.circle")
                                                .resizable().scaledToFit()
                                                .frame(width: 18, height: 18, alignment: .center)
                                                .foregroundColor(overCopyButton ? .accentColor : .secondary)
                                        })
                                        .buttonStyle(PlainButtonStyle())
                                        .onHover{ hovering in overCopyButton = hovering }
                                    }
                                }
                            }
                        } else {
                            Spacer()
                            if devices[index].hasBattery {
                                Text("\(devices[index].batteryLevel)%")
                                    .foregroundColor((devices[index].batteryLevel <= 10) ? Color("dark_my_red") : .primary)
                                    .font(.system(size: 11))
                                BatteryView(item: devices[index])
                                    .scaleEffect(0.85)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .onHover{ hovering in overStack = index }
                }
                .background((overStackNC == mainIndex && overStack == index) ? Color("black_white").opacity(0.15) : .clear)
                .clipShape(RoundedCornersShape(radius: 2.9, corners: index == devices.count - 1 ? [.bottomLeft, .bottomRight] : (index == 0 ? [.topLeft, .topRight] : [])))
                if index != devices.count-1 { Divider() }
            }
        }
        .onHover{ hovering in overStackNC = mainIndex }
        .padding(.horizontal, 6)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.secondary, lineWidth: 1)
                .padding(.vertical, -1)
                .padding(.horizontal, 5)
                .opacity(0.23)
        )
        .offset(y: 2.5)
    }

}

func openAboutPanel() {
    NSApp.activate(ignoringOtherApps: true)
    NSApp.orderFrontStandardAboutPanel(nil)
}

func openSettingPanel() {
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
        if let w = NSApp.windows.first(where: { $0.title == "AirBattery Settings".local }) {
            w.level = .floating
            w.titlebarSeparatorStyle = .none
            guard let nsSplitView = findNSSplitVIew(view: w.contentView),
                  let controller = nsSplitView.delegate as? NSSplitViewController else { return }
            controller.splitViewItems.first?.canCollapse = false
            controller.splitViewItems.first?.minimumThickness = 175
            controller.splitViewItems.first?.maximumThickness = 175
            w.makeKeyAndOrderFront(nil)
            w.makeKey()
        }
    }
}

func findNSSplitVIew(view: NSView?) -> NSSplitView? {
    var queue = [NSView]()
    if let root = view {
        queue.append(root)
    }
    while !queue.isEmpty {
        let current = queue.removeFirst()
        if current is NSSplitView {
            return current as? NSSplitView
        }
        for subview in current.subviews {
            queue.append(subview)
        }
    }
    return nil
}
