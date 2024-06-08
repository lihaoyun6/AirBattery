//
//  widget.swift
//  widget
//
//  Created by apple on 2024/2/18.
//

import WidgetKit
import SwiftUI

@available(macOS 14, *)
struct ViewSizeTimelineProviderNew: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), data: [],family: context.family, mainApp: true, configuration: nil)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        var mainApp = false
        let apps = NSWorkspace.shared.runningApplications
        for app in apps as [NSRunningApplication] { if app.bundleIdentifier == "com.lihaoyun6.AirBattery" { mainApp = true } }
        var data = AirBatteryModel.readData()
        if context.family == .systemSmall || context.family == .systemMedium {
            while data.count < 8 { data.append(Device(hasBattery: false, deviceID: "", deviceType: "blank", deviceName: "", batteryLevel: 0, isCharging: 0, lastUpdate: 0.0)) }
        } else if context.family ==  .systemLarge {
            if data.count >= 11 { data = Array(data[0..<11]) }
        }
        return SimpleEntry(date: Date(), data: data, family: context.family, mainApp: mainApp, configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var mainApp = false
        let apps = NSWorkspace.shared.runningApplications
        for app in apps as [NSRunningApplication] { if app.bundleIdentifier == "com.lihaoyun6.AirBattery" { mainApp = true } }
        var data = AirBatteryModel.readData()
        let entry: SimpleEntry
        if context.family == .systemSmall || context.family == .systemMedium {
            while data.count < 8 { data.append(Device(hasBattery: false, deviceID: "", deviceType: "blank", deviceName: "", batteryLevel: 0, isCharging: 0, lastUpdate: 0.0)) }
        } else if context.family ==  .systemLarge {
            if data.count >= 11 { data = Array(data[0..<11]) }
        }
        entry = SimpleEntry(date: Date(), data: data, family: context.family, mainApp: mainApp, configuration: configuration)
        let entries: [SimpleEntry] = [entry]
        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct ViewSizeTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), data: [],family: context.family, mainApp: true, configuration: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        var mainApp = false
        let apps = NSWorkspace.shared.runningApplications
        for app in apps as [NSRunningApplication] { if app.bundleIdentifier == "com.lihaoyun6.AirBattery" { mainApp = true } }
        var data = AirBatteryModel.readData()
        let entry: SimpleEntry
        if context.family == .systemSmall || context.family == .systemMedium {
            while data.count < 8 { data.append(Device(hasBattery: false, deviceID: "", deviceType: "blank", deviceName: "", batteryLevel: 0, isCharging: 0, lastUpdate: 0.0)) }
        } else if context.family ==  .systemLarge {
            if data.count >= 8 { data = Array(data[0..<8]) }
        }
        entry = SimpleEntry(date: Date(), data: data, family: context.family, mainApp: mainApp, configuration: nil)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        var mainApp = false
        let apps = NSWorkspace.shared.runningApplications
        for app in apps as [NSRunningApplication] { if app.bundleIdentifier == "com.lihaoyun6.AirBattery" { mainApp = true } }
        var data = AirBatteryModel.readData()
        let entry: SimpleEntry
        if context.family == .systemSmall || context.family == .systemMedium {
            while data.count < 8 { data.append(Device(hasBattery: false, deviceID: "", deviceType: "blank", deviceName: "", batteryLevel: 0, isCharging: 0, lastUpdate: 0.0)) }
        } else if context.family ==  .systemLarge {
            if data.count >= 8 { data = Array(data[0..<8]) }
        }
        entry = SimpleEntry(date: Date(), data: data, family: context.family, mainApp: mainApp, configuration: nil)
        let entries: [SimpleEntry] = [entry]
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let data: [Device]
    let family: WidgetFamily
    let mainApp: Bool
    let configuration: Any?
}

struct batteryWidgetEntryView : View {
    var entry: ViewSizeTimelineProvider.Entry
    
    var body: some View {
        VStack {
            switch entry.family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            case .systemExtraLarge:
                EmptyView()
            @unknown default:
                EmptyView()
            }
        }.widgetURL(URL(string: "airbattery://reloadwingets"))
    }
}

struct LargeWidgetView : View {
    var entry: ViewSizeTimelineProvider.Entry
    let lineWidth = 6.0
    
    var body: some View {
        if !entry.mainApp{
            Text("AirBattery is not running\nLaunch the app to make the widget work")
                .multilineTextAlignment(.center)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.gray)
        } else {
            if entry.data.count == 0 {
                VStack(alignment:.leading) {
                    ForEach(0..<8) { index in
                        VStack{
                            HStack() {
                                Image("blank")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20, alignment: .center)
                                Text("                       ")
                                    .font(.system(size: 11))
                                    .frame(height: 31, alignment: .center)
                                    .padding(.horizontal, 7)
                                Spacer()
                                Text("     ")
                                    .font(.system(size: 11))
                                Image("blank")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20, alignment: .center)
                            }
                            if index != 7 { Divider() }
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 15)
            } else {
                VStack(alignment:.leading) {
                    ForEach(entry.data.indices, id: \.self) { index in
                        if index < 8 {
                            let item = entry.data[index]
                            VStack{
                                HStack() {
                                    Image(getDeviceIcon(item))
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                    //.foregroundColor(Color("black_white"))
                                        .frame(width: 20, height: 20, alignment: .center)
                                    Text("\(((Date().timeIntervalSince1970 - item.lastUpdate) / 60) > 10 ? "⚠︎ " : "")\(item.deviceName)")
                                        .font(.system(size: 11))
                                        .frame(height: 31, alignment: .center)
                                        .padding(.horizontal, 7)
                                    Spacer()
                                    if item.batteryLevel <= 10 {
                                        Text("\(item.batteryLevel)%") .font(.system(size: 11))
                                            .foregroundColor(Color("dark_my_red"))
                                    } else {
                                        Text("\(item.batteryLevel)%") .font(.system(size: 11))
                                    }
                                    
                                    /*Image(getBatteryIcon(item))
                                     .resizable()
                                     .aspectRatio(contentMode: .fit)
                                     .frame(width: 20, height: 20, alignment: .center)
                                     */
                                    BatteryView(item: item)
                                        .scaleEffect(0.76)
                                }
                                if index != 7 { Divider() }
                            }
                        }
                    }
                    Spacer()
                }
                .offset(y:4)
                .padding(.vertical, 8)
                .padding(.horizontal, 18)
            }
        }
    }
}

struct SmallWidgetView : View {
    var entry: ViewSizeTimelineProvider.Entry
    let lineWidth = 6.0
    
    var body: some View {
        if !entry.mainApp {
            Text("AirBattery is not running\nLaunch the app to make\nthe widget work")
                .multilineTextAlignment(.center)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.gray)
        } else {
            if entry.data.count == 0 {
                VStack(spacing: 17) {
                    HStack(spacing: 17) {
                        ForEach(0..<2) { index in
                            ZStack {
                                Circle()
                                    .trim(from: 0.0, to: 0.78)
                                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                    .frame(width: 58, alignment: .center)
                                    .rotationEffect(Angle(degrees: 129.6))
                                    .opacity(0.15)
                                Text("    ")
                                    .font(.system(size: 10, weight: .medium))
                                    .offset(y: 25)
                            }
                        }
                    }
                    HStack(spacing: 17) {
                        ForEach(0..<2) { index in
                            ZStack {
                                Circle()
                                    .trim(from: 0.0, to: 0.78)
                                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                    .frame(width: 58, alignment: .center)
                                    .rotationEffect(Angle(degrees: 129.6))
                                    .opacity(0.15)
                                Text("    ")
                                    .font(.system(size: 10, weight: .medium))
                                    .offset(y: 25)
                            }
                        }
                    }
                }
            }else{
                VStack(spacing: 17) {
                    HStack(spacing: 17){
                        ForEach(entry.data[0..<2], id: \.self) { item in
                            ZStack{
                                Group {
                                    Group {
                                        Circle()
                                            .trim(from: 0.0, to: 0.78)
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            .opacity(0.15)
                                        Circle()
                                            .trim(from: CGFloat(abs((min(Double(item.batteryLevel)/100.0*0.78, 0.78))-0.001)), to: CGFloat(abs((min(Double(item.batteryLevel)/100.0*0.78, 0.78))-0.0005)))
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(Color(getPowerColor(item.batteryLevel)))
                                            .shadow(color: .black, radius: lineWidth*0.76, x: 0, y: 0)
                                            .clipShape(
                                                Circle()
                                                    .trim(from: 0.0, to: 0.78)
                                                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            )
                                            .opacity(item.batteryLevel == 100 ? 0 : 1)
                                        Circle()
                                            .trim(from: 0.0, to: Double(item.batteryLevel)/100.0*0.78)
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(Color(getPowerColor(item.batteryLevel)))
                                    }.rotationEffect(Angle(degrees: 129.6))
                                    
                                    Image(getDeviceIcon(item))
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        //.foregroundColor(Color("black_white"))
                                        .frame(width: 26, height: 26, alignment: .center)
                                    
                                    if item.isCharging != 0 {
                                        Image("batt_bolt_mask")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 12, alignment: .center)
                                            .blendMode(.destinationOut)
                                            .offset(y:-29.5)
                                        Image("batt_bolt")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 10, alignment: .center)
                                            .foregroundColor(item.batteryLevel == 100 ? Color("my_green") : Color.primary)
                                            .offset(y:-29.5)
                                    }
                                }.frame(width: 58, height: 58, alignment: .center)
                                Text(item.hasBattery ? "\(item.batteryLevel)%" : "")
                                    .font(.system(size: 10, weight: .medium))
                                    .offset(x: 1, y: 25)
                            }.compositingGroup()
                        }
                    }
                    
                    HStack(spacing: 17){
                        ForEach(entry.data[2..<4], id: \.self) { item in
                            ZStack{
                                Group {
                                    Group {
                                        Circle()
                                            .trim(from: 0.0, to: 0.78)
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            .opacity(0.15)
                                        Circle()
                                            .trim(from: CGFloat(abs((min(Double(item.batteryLevel)/100.0*0.78, 0.78))-0.001)), to: CGFloat(abs((min(Double(item.batteryLevel)/100.0*0.78, 0.78))-0.0005)))
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(Color(getPowerColor(item.batteryLevel)))
                                            .shadow(color: .black, radius: lineWidth*0.76, x: 0, y: 0)
                                            .clipShape(
                                                Circle()
                                                    .trim(from: 0.0, to: 0.78)
                                                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            )
                                            .opacity(item.batteryLevel == 100 ? 0 : 1)
                                        Circle()
                                            .trim(from: 0.0, to: Double(item.batteryLevel)/100.0*0.78)
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(Color(getPowerColor(item.batteryLevel)))
                                    }.rotationEffect(Angle(degrees: 129.6))
                                    
                                    Image(getDeviceIcon(item))
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        //.foregroundColor(Color("black_white"))
                                        .frame(width: 26, height: 26, alignment: .center)
                                    
                                    if item.isCharging != 0 {
                                        Image("batt_bolt_mask")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 12, alignment: .center)
                                            .blendMode(.destinationOut)
                                            .offset(y:-29.5)
                                        Image("batt_bolt")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 10, alignment: .center)
                                            .foregroundColor(item.batteryLevel == 100 ? Color("my_green") : Color.primary)
                                            .offset(y:-29.5)
                                    }
                                }.frame(width: 58, height: 58, alignment: .center)
                                Text(item.hasBattery ? "\(item.batteryLevel)%" : "")
                                    .font(.system(size: 10, weight: .medium))
                                    .offset(x: 1, y: 25)
                            }.compositingGroup()
                        }
                    }
                }
            }
        }
    }
}

struct MediumWidgetView : View {
    var entry: ViewSizeTimelineProvider.Entry
    let lineWidth = 6.0

    var body: some View {
        if !entry.mainApp{
            Text("AirBattery is not running\nLaunch the app to make the widget work")
                .multilineTextAlignment(.center)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.gray)
        } else {
            if entry.data.count == 0 {
                HStack(spacing: 23) {
                    ForEach(0..<4) { index in
                        VStack(spacing: 17){
                            Circle()
                                .stroke(lineWidth: lineWidth)
                                .frame(width: 58, alignment: .center)
                                .opacity(0.15)
                            Text("     ")
                                .font(.system(size: 17))
                                .frame(width: 58, alignment: .center)
                        }
                    }
                }
            } else {
                HStack(spacing: 23) {
                    ForEach(entry.data[0..<4], id: \.self) { item in
                        VStack(spacing: 17){
                            ZStack{
                                Group {
                                    Group {
                                        Circle()
                                            .stroke(lineWidth: lineWidth)
                                            .opacity(0.15)
                                        Circle()
                                            .trim(from: 0.0, to: CGFloat(min(Double(item.batteryLevel)/100.0, 0.5)))
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(Color(getPowerColor(item.batteryLevel)))
                                        Circle()
                                            .trim(from: CGFloat(abs((min(Double(item.batteryLevel)/100.0, 1.0))-0.001)), to: CGFloat(abs((min(Double(item.batteryLevel)/100.0, 1.0))-0.0005)))
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(Color(getPowerColor(item.batteryLevel)))
                                            .shadow(color: .black, radius: lineWidth*0.76, x: 0, y: 0)
                                            .clipShape( Circle().stroke(lineWidth: lineWidth) )
                                        Circle()
                                            .trim(from: item.batteryLevel > 50 ? 0.25 : 0, to: CGFloat(min(Double(item.batteryLevel)/100.0, 1.0)))
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(Color(getPowerColor(item.batteryLevel)))
                                    }.rotationEffect(Angle(degrees: 270.0))
                                    
                                    Image(getDeviceIcon(item))
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        //.foregroundColor(Color("black_white"))
                                        .frame(width: 26, height: 26, alignment: .center)
                                    
                                    if item.isCharging != 0 {
                                        Image("batt_bolt_mask")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 12, alignment: .center)
                                            .blendMode(.destinationOut)
                                            .offset(y:-29.5)
                                        Image("batt_bolt")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 10, alignment: .center)
                                            .foregroundColor(item.batteryLevel == 100 ? Color("my_green") : Color.primary)
                                            .offset(y:-29.5)
                                    }
                                }
                                .frame(width: 58, height: 58, alignment: .center)
                                //if item.isCharging != 0 { Image("charging").offset(y:-29.2) }
                            }.compositingGroup()
                            
                            Text(item.hasBattery ? "\(item.batteryLevel)%" : "")
                                .font(.system(size: 17))
                                .frame(width: 58, alignment: .center)
                        }
                    }
                }
                .offset(y:3)
            }
        }
    }
}

struct BatteryView: View {
    var item: Device
    var body: some View {
        let width = round(max(1, min(19, Double(item.batteryLevel)/100*19)))
        ZStack{
            ZStack(alignment: .leading) {
                Image("batt_outline_bold")
                Group{
                    Rectangle()
                        .fill(Color(getPowerColor(item.batteryLevel)))
                        .frame(width: width, height: 8, alignment: .leading)
                        .clipShape(RoundedRectangle(cornerRadius: 1.5, style: .continuous))
                }.offset(x:2)
            }
            //.frame(width: 25.5, height: 12, alignment: .leading)
            if item.deviceID == "@MacInternalBattery" {
                if item.acPowered {
                    Image("batt_" + ((item.isCharging != 0 || item.isCharged) ? "bolt" : "plug") + "_mask")
                        .blendMode(.destinationOut)
                        .offset(x:-1.5)
                    Image("batt_" + ((item.isCharging != 0 || item.isCharged) ? "bolt" : "plug"))
                        .offset(x:-1.5)
                        .foregroundColor(Color("black_white"))
                }
            }else{
                if item.isCharging != 0 {
                    Image("batt_" + ((item.isCharging == 5) ? "plug" : "bolt") + "_mask")
                        .blendMode(.destinationOut)
                        .offset(x:-1.5)
                    Image("batt_" + ((item.isCharging == 5) ? "plug" : "bolt"))
                        .offset(x:-1.5)
                        .foregroundColor(Color("black_white"))
                }
            }
        }.compositingGroup()
    }
}

struct batteryWidget: Widget {
    let kind: String = "widget.battery"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ViewSizeTimelineProvider()) { entry in
            batteryWidgetEntryView(entry: entry)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .widgetBackground(Color("WidgetBackground"))
        }
        .configurationDisplayName("Batteries")
        .description("Displays battery usage for your devices from AirBattery")
        .disableContentMarginsIfNeeded()
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
