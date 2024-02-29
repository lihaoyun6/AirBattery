//
//  ContentView.swift
//  AirBattery
//
//  Created by apple on 2023/9/4.
//
import AppKit
import SwiftUI

struct MultiBatteryView: View {
    @AppStorage("showThisMac") var showThisMac = "icon"
    @AppStorage("machineName") var machineName = "Mac"
    @AppStorage("rollingMode") var rollingMode = "auto"
    @AppStorage("showOn") var showOn = "both"
    
    @State var statusBarItem: NSStatusItem

    @State private var rollCount = 1
    @State private var darkMode = getDarkMode()
    @State private var lastTime = Double(Date().timeIntervalSince1970)
    @State private var batteryList = AirBatteryModel.getAll()
    
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
                Group {
                    Circle()
                        .stroke(lineWidth: 6.0*1.2)
                        .opacity(darkMode ? 0.2 : 0.13)
                        .foregroundColor(darkMode ? .white : .black)
                    Circle()
                        .trim(from: 0.0, to: 0.0)
                        .stroke(style: StrokeStyle(lineWidth: 6.0, lineCap: .round, lineJoin: .round))
                        .foregroundColor(.clear)
                        .rotationEffect(Angle(degrees: 270.0))
                    Circle()
                        .trim(from: CGFloat(abs(0.0-0.001)), to: CGFloat(abs(0.0-0.0005)))
                        .stroke(style: StrokeStyle(lineWidth: 6.0, lineCap: .round, lineJoin: .round))
                        .foregroundColor(.clear)
                        .shadow(color: .black, radius: 6.0*0.76, x: 0, y: 0)
                        .rotationEffect(Angle(degrees: 270.0))
                        .clipShape( Circle().stroke(lineWidth: 6.0) )
                    Circle()
                        .trim(from: 0, to: 0.0)
                        .stroke(style: StrokeStyle(lineWidth: 6.0, lineCap: .round, lineJoin: .round))
                        .foregroundColor(.clear)
                        .rotationEffect(Angle(degrees: 270.0))
                }
                .offset(x:-24, y: -24)
                .frame(width: 38, height: 38, alignment: .center)
            } else {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        ForEach(batteryList[0..<2], id: \.self) { item in
                            ZStack {
                                Group {
                                    Circle()
                                        .stroke(lineWidth: 6.0*1.2)
                                        .opacity(darkMode ? 0.2 : 0.13)
                                        .foregroundColor(darkMode ? .white : .black)
                                    Circle()
                                        .trim(from: 0.0, to: CGFloat(min(Double(item.batteryLevel)/100.0, 0.5)))
                                        .stroke(style: StrokeStyle(lineWidth: 6.0, lineCap: .round, lineJoin: .round))
                                        .foregroundColor(Color(getPowerColor(item.batteryLevel)))
                                        .rotationEffect(Angle(degrees: 270.0))
                                    Circle()
                                        .trim(from: CGFloat(abs((min(Double(item.batteryLevel)/100.0, 1.0))-0.001)), to: CGFloat(abs((min(Double(item.batteryLevel)/100.0, 1.0))-0.0005)))
                                        .stroke(style: StrokeStyle(lineWidth: 6.0, lineCap: .round, lineJoin: .round))
                                        .foregroundColor(Color(getPowerColor(item.batteryLevel)))
                                        .shadow(color: .black, radius: 6.0*0.76, x: 0, y: 0)
                                        .rotationEffect(Angle(degrees: 270.0))
                                        .clipShape( Circle().stroke(lineWidth: 6.0) )
                                    Circle()
                                        .trim(from: item.batteryLevel > 50 ? 0.25 : 0, to: CGFloat(min(Double(item.batteryLevel)/100.0, 1.0)))
                                        .stroke(style: StrokeStyle(lineWidth: 6.0, lineCap: .round, lineJoin: .round))
                                        .foregroundColor(Color(getPowerColor(item.batteryLevel)))
                                        .rotationEffect(Angle(degrees: 270.0))
                                    
                                    if item.deviceType == "Mac" && showThisMac == "percent"{
                                        Text(String(item.batteryLevel))
                                            .colorScheme(darkMode ? .dark : .light)
                                            .foregroundColor(item.isCharging != 0 ? Color("dark_"+getPowerColor(item.batteryLevel)) : Color("black_white"))
                                            .font(.custom("Helvetica-Bold", size: item.batteryLevel>99 ? 32 : 42))
                                            .frame(width: 100, alignment: .center)
                                            .scaleEffect(0.5)
                                            .offset(x:-0.2, y:1.5)
                                        
                                    } else {
                                        Image(getDeviceIcon(item))
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .colorScheme(darkMode ? .dark : .light)
                                            .foregroundColor(item.isCharging != 0 ? Color("dark_"+getPowerColor(item.batteryLevel)) : Color("black_white"))
                                            .offset(x:0.6, y:0.6)
                                            .frame(width: 44, height: 44, alignment: .center)
                                            .scaleEffect(0.5)
                                    }
                                }
                                .frame(width: 38, height: 38, alignment: .center)
                            }
                            
                        }
                    }
                    HStack(spacing: 10) {
                        ForEach(batteryList[2..<4], id: \.self) { item in
                            ZStack {
                                Group {
                                    Circle()
                                        .stroke(lineWidth: 6.0*1.2)
                                        .opacity(darkMode ? 0.2 : 0.13)
                                        .foregroundColor(darkMode ? .white : .black)
                                    Circle()
                                        .trim(from: 0.0, to: CGFloat(min(Double(item.batteryLevel)/100.0, 0.5)))
                                        .stroke(style: StrokeStyle(lineWidth: 6.0, lineCap: .round, lineJoin: .round))
                                        .foregroundColor(Color(getPowerColor(item.batteryLevel)))
                                        .rotationEffect(Angle(degrees: 270.0))
                                    Circle()
                                        .trim(from: CGFloat(abs((min(Double(item.batteryLevel)/100.0, 1.0))-0.001)), to: CGFloat(abs((min(Double(item.batteryLevel)/100.0, 1.0))-0.0005)))
                                        .stroke(style: StrokeStyle(lineWidth: 6.0, lineCap: .round, lineJoin: .round))
                                        .foregroundColor(Color(getPowerColor(item.batteryLevel)))
                                        .shadow(color: .black, radius: 6.0*0.76, x: 0, y: 0)
                                        .rotationEffect(Angle(degrees: 270.0))
                                        .clipShape( Circle().stroke(lineWidth: 6.0) )
                                    Circle()
                                        .trim(from: item.batteryLevel > 50 ? 0.25 : 0, to: CGFloat(min(Double(item.batteryLevel)/100.0, 1.0)))
                                        .stroke(style: StrokeStyle(lineWidth: 6.0, lineCap: .round, lineJoin: .round))
                                        .foregroundColor(Color(getPowerColor(item.batteryLevel)))
                                        .rotationEffect(Angle(degrees: 270.0))
                                    Image(getDeviceIcon(item))
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .colorScheme(darkMode ? .dark : .light)
                                        .foregroundColor(item.isCharging != 0 ? Color("dark_"+getPowerColor(item.batteryLevel)) : Color("black_white"))
                                        .offset(x:0.6, y:0.6)
                                        .frame(width: 44, height: 44, alignment: .center)
                                        .scaleEffect(0.5)
                                    
                                }
                                .frame(width: 38, height: 38, alignment: .center)
                            }
                            
                        }
                    }
                }
            }
        }
        .frame(width: 128, height: 128, alignment: .center)
        .onReceive(widgetTimer){_ in
            AirBatteryModel.writeData()
            //WidgetCenter.shared.reloadAllTimelines()
        }
        .onReceive(dockTimer) { t in
            NSApp.dockTile.display()
            InternalBattery.status = getPowerState()
            let windows = NSApplication.shared.windows
            for w in windows { if w.level.rawValue == 0 || w.level.rawValue == 3 { w.level = .floating } }
            if showOn == "sbar"{
                if statusBarItem.isVisible == false { statusBarItem.isVisible.toggle() }
                if NSApp.activationPolicy() != .accessory { NSApp.setActivationPolicy(.accessory) }
            } else if showOn == "both" {
                if statusBarItem.isVisible == false { statusBarItem.isVisible.toggle() }
                if NSApp.activationPolicy() != .regular { NSApp.setActivationPolicy(.regular) }
            } else {
                if statusBarItem.isVisible == true { statusBarItem.isVisible.toggle() }
                if NSApp.activationPolicy() != .regular { NSApp.setActivationPolicy(.regular) }
            }
            
            if let result = process(path: "/usr/sbin/system_profiler", arguments: ["SPBluetoothDataType", "-json"]) { SPBluetoothDataModel.data = result }
            
            darkMode = getDarkMode()
            var list = AirBatteryModel.getAll()
            let ibStatus = InternalBattery.status
            let now = Double(t.timeIntervalSince1970)
            
            
            if rollingMode == "off" { rollCount = 1 }
            if ibStatus.hasBattery && showThisMac != "hidden" { list.insert(ibToAb(ibStatus), at: 0) }

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
        }
    }
}

struct popover: View {
    var allDevices: [Device]
    let hiddenDevices = AirBatteryModel.getBlackList()
    @State private var overHideButton = false
    @State private var overInfoButton = false
    @State private var overQuitButton = false
    @State private var overSettButton = false
    @State private var overStack = -1
    @State private var overStack2 = -1
    @State private var hidden:[Int] = []
    @State private var hidden2:[Int] = []
    
    var body: some View {
        VStack(spacing: 0){
            HStack(spacing: 4){
                Button(action: {
                    NSApp.terminate(self)
                }, label: {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 9.6, weight: .semibold))
                        .frame(width: 10, height: 20, alignment: .center)
                        .foregroundColor(overQuitButton ? .red : .secondary)
                })
                .buttonStyle(PlainButtonStyle())
                .onHover{ hovering in overQuitButton = hovering }
                
                Button(action: {
                    NSApp.orderFrontStandardAboutPanel(nil)
                }, label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 9.6, weight: .semibold))
                        .frame(width: 10, height: 20, alignment: .center)
                        .foregroundColor(overInfoButton ? .accentColor : .secondary)
                })
                .buttonStyle(PlainButtonStyle())
                .onHover{ hovering in overInfoButton = hovering }
                
                Button(action: {
                    if #available(macOS 14, *) {
                        NSApp.mainMenu?.items.first?.submenu?.item(at: 2)?.performAction()
                    }else if #available(macOS 13, *) {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    } else {
                        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                    }
                    NSApp.activate(ignoringOtherApps: true)
                }, label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 9.6, weight: .semibold))
                        .frame(width: 10, height: 20, alignment: .center)
                        .foregroundColor(overSettButton ? .accentColor : .secondary)
                })
                .buttonStyle(PlainButtonStyle())
                .onHover{ hovering in overSettButton = hovering }
                
                Spacer()
            }
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
                                Spacer()
                                
                                if overStack == index {
                                    if allDevices[index].deviceID == "@MacInternalBattery" {
                                        //Image(systemName: "clock").font(.system(size: 10))
                                        Text(allDevices[index].isCharging != 0 ? "Until full:" : "Until empty:")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                        Text(InternalBattery.status.timeLeft)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }else{
                                        //Image(systemName: "arrow.clockwise").font(.system(size: 10))
                                        Text("\(Int((Date().timeIntervalSince1970 - allDevices[index].lastUpdate) / 60))"+" mins ago".local)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
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
                                } else {
                                    Text("\(allDevices[index].batteryLevel)%")
                                            .foregroundColor((allDevices[index].batteryLevel <= 10) ? Color("dark_my_red") : .secondary)
                                            .font(.system(size: 11))
                                    BatteryView(item: allDevices[index])
                                        .scaleEffect(0.8)
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(overStack == index ? Color("black_white").opacity(0.15) : .clear)//.cornerRadius(4)
                            .clipShape(RoundedCornersShape(radius: 1.9, corners: index == allDevices.count - (hiddenDevices.count > 0 ? 0 : 1) ? [.bottomLeft, .bottomRight] : (index == 0 ? [.topLeft, .topRight] : [])))
                            .onHover{ hovering in
                                overStack2 = -1
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
        }.offset(y:-3)
    }
}
