//
//  widget.swift
//  widget
//
//  Created by apple on 2024/2/18.
//

import WidgetKit
import SwiftUI

struct ViewSizeTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), data: [],family: context.family, mainApp: true)
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
        entry = SimpleEntry(date: Date(), data: data, family: context.family, mainApp: mainApp)
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
        entry = SimpleEntry(date: Date(), data: data, family: context.family, mainApp: mainApp)
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
        }
    }
}

struct LargeWidgetView : View {
    var entry: ViewSizeTimelineProvider.Entry
    let lineWidth = 6.0
    
    var body: some View {
        if !entry.mainApp{
            Text("AirBattery is not running\nLaunch the app to make the widget work.".local)
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
                                Text("Device Name Placeholder")
                                    .font(.system(size: 11))
                                    .frame(height: 31, alignment: .center)
                                    .padding(.horizontal, 7)
                                Spacer()
                                Text("100%")
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
                    ForEach(entry.data, id: \.self) { item in
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
                            if entry.data.firstIndex(of: item) != 7 { Divider() }
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
            Text("AirBattery is not running\nLaunch the app to make\nthe widget work.".local)
                .multilineTextAlignment(.center)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.gray)
        } else {
            if entry.data.count == 0 {
                VStack(spacing: 17) {
                    HStack(spacing: 17) {
                        ForEach(0..<2) { index in
                            Circle()
                                .stroke(lineWidth: lineWidth)
                                .frame(width: 58, alignment: .center)
                        }
                    }
                    HStack(spacing: 17) {
                        ForEach(0..<2) { index in
                            Circle()
                                .stroke(lineWidth: lineWidth)
                                .frame(width: 58, alignment: .center)
                        }
                    }
                }.opacity(0.15)
            }else{
                VStack(spacing: 17) {
                    HStack(spacing: 17){
                        ForEach(entry.data[0..<2], id: \.self) { item in
                            ZStack{
                                Group {
                                    Circle()
                                        .stroke(lineWidth: lineWidth)
                                        .opacity(0.15)
                                    Circle()
                                        .trim(from: 0.0, to: CGFloat(min(Double(item.batteryLevel)/100.0, 0.5)))
                                        .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                        .foregroundColor(Color(getPowerColor(item.batteryLevel)))
                                        .rotationEffect(Angle(degrees: 270.0))
                                    Circle()
                                        .trim(from: CGFloat(abs((min(Double(item.batteryLevel)/100.0, 1.0))-0.001)), to: CGFloat(abs((min(Double(item.batteryLevel)/100.0, 1.0))-0.0005)))
                                        .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                        .foregroundColor(Color(getPowerColor(item.batteryLevel)))
                                        .shadow(color: .black, radius: lineWidth*0.76, x: 0, y: 0)
                                        .rotationEffect(Angle(degrees: 270.0))
                                        .clipShape( Circle().stroke(lineWidth: lineWidth) )
                                    Circle()
                                        .trim(from: item.batteryLevel > 50 ? 0.25 : 0, to: CGFloat(min(Double(item.batteryLevel)/100.0, 1.0)))
                                        .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                        .foregroundColor(Color(getPowerColor(item.batteryLevel)))
                                        .rotationEffect(Angle(degrees: 270.0))
                                    
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
                        }
                    }
                    
                    HStack(spacing: 17){
                        ForEach(entry.data[2..<4], id: \.self) { item in
                            ZStack{
                                Group {
                                    Circle()
                                        .stroke(lineWidth: lineWidth)
                                        .opacity(0.15)
                                    Circle()
                                        .trim(from: 0.0, to: CGFloat(min(Double(item.batteryLevel)/100.0, 0.5)))
                                        .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                        .foregroundColor(Color(getPowerColor(item.batteryLevel)))
                                        .rotationEffect(Angle(degrees: 270.0))
                                    Circle()
                                        .trim(from: CGFloat(abs((min(Double(item.batteryLevel)/100.0, 1.0))-0.001)), to: CGFloat(abs((min(Double(item.batteryLevel)/100.0, 1.0))-0.0005)))
                                        .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                        .foregroundColor(Color(getPowerColor(item.batteryLevel)))
                                        .shadow(color: .black, radius: lineWidth*0.76, x: 0, y: 0)
                                        .rotationEffect(Angle(degrees: 270.0))
                                        .clipShape( Circle().stroke(lineWidth: lineWidth) )
                                    Circle()
                                        .trim(from: item.batteryLevel > 50 ? 0.25 : 0, to: CGFloat(min(Double(item.batteryLevel)/100.0, 1.0)))
                                        .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                        .foregroundColor(Color(getPowerColor(item.batteryLevel)))
                                        .rotationEffect(Angle(degrees: 270.0))
                                    
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
            Text("AirBattery is not running\nLaunch the app to make the widget work.".local)
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
                            Text("100%")
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
                                    Circle()
                                        .stroke(lineWidth: lineWidth)
                                        .opacity(0.15)
                                    Circle()
                                        .trim(from: 0.0, to: CGFloat(min(Double(item.batteryLevel)/100.0, 0.5)))
                                        .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                        .foregroundColor(Color(getPowerColor(item.batteryLevel)))
                                        .rotationEffect(Angle(degrees: 270.0))
                                    Circle()
                                        .trim(from: CGFloat(abs((min(Double(item.batteryLevel)/100.0, 1.0))-0.001)), to: CGFloat(abs((min(Double(item.batteryLevel)/100.0, 1.0))-0.0005)))
                                        .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                        .foregroundColor(Color(getPowerColor(item.batteryLevel)))
                                        .shadow(color: .black, radius: lineWidth*0.76, x: 0, y: 0)
                                        .rotationEffect(Angle(degrees: 270.0))
                                        .clipShape( Circle().stroke(lineWidth: lineWidth) )
                                    Circle()
                                        .trim(from: item.batteryLevel > 50 ? 0.25 : 0, to: CGFloat(min(Double(item.batteryLevel)/100.0, 1.0)))
                                        .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                        .foregroundColor(Color(getPowerColor(item.batteryLevel)))
                                        .rotationEffect(Angle(degrees: 270.0))
                                    
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

struct batteryWidget: Widget {
    let kind: String = "widget.battery"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ViewSizeTimelineProvider()) { entry in
            batteryWidgetEntryView(entry: entry)
                .ignoresSafeArea()
                .widgetBackground(Color("WidgetBackground"))
        }
        .configurationDisplayName("Batteries")
        .description("Displays battery information for your devices from AirBattery.")
        .disableContentMarginsIfNeeded()
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
        ])
    }
}
