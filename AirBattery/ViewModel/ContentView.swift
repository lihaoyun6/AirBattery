//
//  ContentView.swift
//  AirBattery
//
//  Created by apple on 2023/9/4.
//
import AppKit
import SwiftUI
import WidgetKit
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

struct MultiBatteryView: View {
    @AppStorage("showThisMac") var showThisMac = "icon"
    //@AppStorage("machineType") var machineType = "Mac"
    @AppStorage("rollingMode") var rollingMode = "auto"
    @AppStorage("showOn") var showOn = "both"
    @AppStorage("deviceName") var deviceName = "Mac"
    @AppStorage("widgetInterval") var widgetInterval = 0
    @AppStorage("nearCast") var nearCast = false
    @AppStorage("ncGroupID") var ncGroupID = ""
    @AppStorage("readBTHID") var readBTHID = true
    
    //@State var statusBarItem: NSStatusItem

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
                                    
                                    if item.deviceType == "Mac" && showThisMac == "percent"{
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
        .onReceive(alertTimer) {_ in batteryAlert() }
        .onReceive(widgetDataTimer) {_ in
            if let result = process(path: "/usr/sbin/system_profiler", arguments: ["SPBluetoothDataType", "-json"]) {
                SPBluetoothDataModel.data = result
            }
            AirBatteryModel.writeData()
        }
        .onReceive(widgetViewTimer) {_ in if widgetInterval != -1 { WidgetCenter.shared.reloadAllTimelines() }}
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
            InternalBattery.status = getPowerState()
            //for w in NSApplication.shared.windows { if w.level.rawValue == 0 || w.level.rawValue == 3 { w.level = .floating } }
            
            if showOn == "both" || showOn == "dock" {
                darkMode = getDarkMode()
                var list = AirBatteryModel.getAll()
                let ibStatus = InternalBattery.status
                let now = Double(t.timeIntervalSince1970)
                
                if rollingMode == "off" { rollCount = 1 }
                if ibStatus.hasBattery && showThisMac != "hidden" { list.insert(ib2ab(ibStatus), at: 0) }
                
                batteryList = sliceList(data: list, length: 4, count: rollCount)
                if batteryList == []{
                    rollCount = 1
                    batteryList = sliceList(data: list, length: 4, count: rollCount)
                }
                
                if now - lastTime >= 20 && (rollingMode == "on" || rollingMode == "auto") {
                    if rollingMode == "auto" {
                        if list.count > 4 {
                            lastTime = now
                            rollCount = rollCount + 1
                        }
                    } else {
                        lastTime = now
                        rollCount = rollCount + 1
                    }
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
    var allDevices: [Device]
    let hiddenDevices = AirBatteryModel.getBlackList()
    @AppStorage("nearCast") var nearCast = false
    @State private var overReloadButton = false
    @State private var overCopyButton = false
    @State private var overHideButton = false
    @State private var overAlertButton = false
    @State private var overInfoButton = false
    @State private var overQuitButton = false
    @State private var overSettButton = false
    @State private var overReloButton = false
    @State private var overStack = -1
    @State private var overStack2 = -1
    @State private var overStackNC = -1
    @State private var hidden:[Int] = []
    @State private var hidden2:[Int] = []
    @State private var alertList = (UserDefaults.standard.object(forKey: "alertList") ?? []) as! [String]
    @State private var allNearcast = getFiles(withExtension: "json", in: ncFolder)
    
    var body: some View {
        ZStack{
            if fromDock { Color.clear.background(BlurView(material: .menu)) }
            VStack(spacing: 0){
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
                        .buttonStyle(PlainButtonStyle())
                        .onHover{ hovering in overQuitButton = hovering }
                    } else {
                        Button(action: {
                            if let window = NSApp.windows.first(where: { $0.title == "AirBattery Dock Window" }) { window.orderOut(nil) }
                        }, label: {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 14, weight: .light))
                                .frame(width: 14, height: 14, alignment: .center)
                                .foregroundColor(overQuitButton ? Color("my_yellow") : .secondary)
                                .opacity(overQuitButton ? 1 : 0.7)
                        })
                        .buttonStyle(PlainButtonStyle())
                        .onHover{ hovering in overQuitButton = hovering }
                    }
                    
                    Button(action: {
                        if let window = NSApp.windows.first(where: { $0.title == "AirBattery Dock Window" }) { window.orderOut(nil) }
                        AppDelegate.shared.openAboutPanel()
                    }, label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14, weight: .light))
                            .frame(width: 16, height: 14, alignment: .center)
                            .foregroundColor(overInfoButton ? .accentColor : .secondary)
                            .opacity(overInfoButton ? 1 : 0.7)
                    })
                    .buttonStyle(PlainButtonStyle())
                    .onHover{ hovering in overInfoButton = hovering }
                    
                    Button(action: {
                        AppDelegate.shared.openSettingPanel()
                    }, label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13.6, weight: .light))
                            .frame(width: 14, height: 14, alignment: .center)
                            .foregroundColor(overSettButton ? .accentColor : .secondary)
                            .opacity(overSettButton ? 1 : 0.7)
                    })
                    .buttonStyle(PlainButtonStyle())
                    .onHover{ hovering in overSettButton = hovering }
                    Spacer()
                    if fromDock {
                        Text("Click Dock icon again to hide this panel")
                            .font(.system(size: 10, weight: .light))
                            .foregroundColor(.secondary)
                            .opacity(0.7).offset(y: 0.5)
                    }
                    if nearCast {
                        Button(action: {
                            netcastService.refeshAll()
                        }, label: {
                            Image(systemName: "arrow.clockwise.circle")
                                .font(.system(size: 14, weight: .light))
                                .frame(width: 14, height: 14, alignment: .center)
                                .foregroundColor(overReloButton ? .accentColor : .secondary)
                                .opacity(overReloButton ? 1 : 0.7)
                        })
                        .buttonStyle(PlainButtonStyle())
                        .onHover{ hovering in overReloButton = hovering }
                    }
                }
                .offset(y: -3.5)
                .padding(.horizontal, 5)
                .onHover{ hovering in (overStack, overStack2) = (-1, -1) }
                VStack(alignment:.leading,spacing: 0) {
                    if allDevices.count < 1 {
                        HStack{
                            Image(systemName: "exclamationmark.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(Color("black_white"))
                                .frame(width: 20, height: 20, alignment: .center)
                            Text("No Device Found!")
                                .font(.system(size: 12))
                                .foregroundColor(Color("black_white"))
                                .frame(height: 24, alignment: .center)
                                .padding(.horizontal, 8)
                            Spacer()
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 11)
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
                                    Text("\(((Date().timeIntervalSince1970 - allDevices[index].lastUpdate) / 60) > 10 ? "⚠︎ " : "")\(allDevices[index].deviceName)")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color("black_white"))
                                        .frame(height: 24, alignment: .center)
                                        .padding(.horizontal, 7)
                                    if alertList.contains(allDevices[index].deviceName) {
                                        Image(systemName: "bell.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(Color("black_white"))
                                            .frame(height: 24, alignment: .center)
                                            .padding(.leading, -10)
                                    }
                                    Spacer()
                                    if allDevices[index].hasBattery {
                                        if overStack == index {
                                            HStack(spacing: 4) {
                                                if allDevices[index].deviceID == "@MacInternalBattery" {
                                                    Text(allDevices[index].isCharging != 0 ? "Until Full:" : "Until Empty:")
                                                        .font(.system(size: 11))
                                                    Text(InternalBattery.status.timeLeft)
                                                        .font(.system(size: 11))
                                                } else {
                                                    if allDevices[index].realUpdate != 0.0 {
                                                        Text("\(Int((Date().timeIntervalSince1970 - allDevices[index].realUpdate) / 60))"+" mins ago".local)
                                                            .font(.system(size: 11))
                                                    } else {
                                                        Text("\(Int((Date().timeIntervalSince1970 - allDevices[index].lastUpdate) / 60))"+" mins ago".local)
                                                            .font(.system(size: 11))
                                                    }
                                                }
                                                if !alertList.contains(allDevices[index].deviceName) {
                                                    Button(action: {
                                                        alertList = (UserDefaults.standard.object(forKey: "alertList") ?? []) as! [String]
                                                        alertList.append(allDevices[index].deviceName)
                                                        UserDefaults.standard.set(alertList, forKey: "alertList")
                                                    }, label: {
                                                        Image(systemName: "bell")
                                                            .frame(width: 20, height: 20, alignment: .center)
                                                            .foregroundColor(overAlertButton ? .accentColor : .secondary)
                                                    })
                                                    .buttonStyle(PlainButtonStyle())
                                                    .onHover{ hovering in overAlertButton = hovering }
                                                } else {
                                                    Button(action: {
                                                        alertList = (UserDefaults.standard.object(forKey: "alertList") ?? []) as! [String]
                                                        alertList.removeAll { $0 == allDevices[index].deviceName }
                                                        UserDefaults.standard.set(alertList, forKey: "alertList")
                                                    }, label: {
                                                        Image(systemName: "bell.fill")
                                                            .frame(width: 20, height: 20, alignment: .center)
                                                            .foregroundColor(overAlertButton ? .accentColor : .secondary)
                                                    })
                                                    .buttonStyle(PlainButtonStyle())
                                                    .onHover{ hovering in overAlertButton = hovering }
                                                }
                                                if #available(macOS 14, *) {
                                                    Button(action: {
                                                        copyToClipboard(allDevices[index].deviceName)
                                                        _ = createAlert(title: "Device Name Copied".local,
                                                                        message: String(format: "Device name: \"%@\" has been copied to the clipboard.".local, allDevices[index].deviceName),
                                                                        button1: "OK".local).runModal()
                                                    }, label: {
                                                        Image(systemName: "list.clipboard.fill")
                                                            .frame(width: 20, height: 20, alignment: .center)
                                                            .foregroundColor(overCopyButton ? .accentColor : .secondary)
                                                    })
                                                    .buttonStyle(PlainButtonStyle())
                                                    .onHover{ hovering in overCopyButton = hovering }
                                                }
                                                
                                                if allDevices[index].deviceID != "@MacInternalBattery" {
                                                    Button(action: {
                                                        hidden.append(index)
                                                        var blackList = (UserDefaults.standard.object(forKey: "blackList") ?? []) as! [String]
                                                        blackList.append(allDevices[index].deviceName)
                                                        UserDefaults.standard.set(blackList, forKey: "blackList")
                                                    }, label: {
                                                        Image(systemName: "eye.slash.fill")
                                                            .frame(width: 20, height: 20, alignment: .center)
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
                                                .scaleEffect(0.8)
                                        }
                                    }
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(overStack == index ? Color("black_white").opacity(0.15) : .clear)//.cornerRadius(4)
                                .clipShape(RoundedCornersShape(radius: 1.9, corners: index == allDevices.count - (hiddenDevices.count > 0 ? 0 : 1) ? [.bottomLeft, .bottomRight] : (index == 0 ? [.topLeft, .topRight] : [])))
                                .onHover{ hovering in
                                    overStack2 = -1
                                    overStackNC = -1
                                    if overStack != index { overStack = index }
                                }
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
                                        var blackList = (UserDefaults.standard.object(forKey: "blackList") ?? []) as! [String]
                                        blackList.removeAll { $0 == hiddenDevices[index].deviceName }
                                        UserDefaults.standard.set(blackList, forKey: "blackList")
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
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(Color.secondary, lineWidth: 1)
                        .padding(.vertical, -1)
                        .padding(.horizontal, 5)
                        .opacity(0.23)
                )
                .offset(y: 2.5)
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
        }
    }
}

struct nearcastView: View {
    var devices: [Device]
    var mainIndex: Int
    @Binding var overStackNC: Int
    @State private var overStack = -1
    @State private var overCopyButton = false
    
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
                        Text("\(((Date().timeIntervalSince1970 - devices[index].lastUpdate) / 60) > 10 ? "⚠︎ " : "")\(devices[index].deviceName)")
                            .font(.system(size: 12))
                            .foregroundColor(Color("black_white"))
                            .frame(height: 24, alignment: .center)
                            .padding(.horizontal, 7)
                        if overStackNC == mainIndex && overStack == index {
                            Spacer()
                            Text("\(Int((Date().timeIntervalSince1970 - devices[index].lastUpdate) / 60))"+" mins ago".local)
                                .font(.system(size: 11))
                            if devices[index].hasBattery {
                                if #available(macOS 14, *) {
                                    Button(action: {
                                        copyToClipboard(devices[index].deviceName)
                                        _ = createAlert(title: "Device Name Copied".local,
                                                        message: String(format: "Device name: \"%@\" has been copied to the clipboard.".local, devices[index].deviceName),
                                                        button1: "OK".local).runModal()
                                    }, label: {
                                        Image(systemName: "list.clipboard.fill")
                                            .frame(width: 20, height: 20, alignment: .center)
                                            .foregroundColor(overCopyButton ? .accentColor : .secondary)
                                    })
                                    .buttonStyle(PlainButtonStyle())
                                    .onHover{ hovering in overCopyButton = hovering }
                                }
                            }
                        } else {
                            Spacer()
                            if devices[index].hasBattery {
                                Text("\(devices[index].batteryLevel)%")
                                    .foregroundColor((devices[index].batteryLevel <= 10) ? Color("dark_my_red") : .primary)
                                    .font(.system(size: 11))
                                BatteryView(item: devices[index])
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .onHover{ hovering in overStack = index }
                }
                .background((overStackNC == mainIndex && overStack == index) ? Color("black_white").opacity(0.15) : .clear)
                .clipShape(RoundedCornersShape(radius: 1.9, corners: index == devices.count - 1 ? [.bottomLeft, .bottomRight] : (index == 0 ? [.topLeft, .topRight] : [])))
                if index != devices.count-1 { Divider() }
            }
        }
        .onHover{ hovering in overStackNC = mainIndex }
        .padding(.horizontal, 6)
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(Color.secondary, lineWidth: 1)
                .padding(.vertical, -1)
                .padding(.horizontal, 5)
                .opacity(0.23)
        )
        .offset(y: 2.5)
    }

}
