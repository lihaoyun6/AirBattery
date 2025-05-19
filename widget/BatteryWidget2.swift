//
//  DoubleBatteryWidget.swift
//  AirBatteryWidgetExtension
//
//  Created by apple on 2024/2/20.
//

import WidgetKit
import SwiftUI

struct LargeWidgetView2: View {
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
                    ForEach(0..<11) { index in
                        VStack{
                            HStack() {
                                Image("blank")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20, alignment: .center)
                                Text("                       ")
                                    .font(.system(size: 11))
                                    .frame(height: 20, alignment: .center)
                                    .padding(.horizontal, 7)
                                Spacer()
                                Text("     ")
                                    .font(.system(size: 11))
                                Image("blank")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20, alignment: .center)
                            }
                            if index != 10 { Divider().padding(.top, -2) }
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 15)
            } else {
                VStack(alignment:.leading) {
                    ForEach(entry.data.indices, id: \.self) { index in
                        let item = entry.data[index]
                        VStack{
                            HStack() {
                                Image(getDeviceIcon(item))
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20, alignment: .center)
                                Text("\(((Date().timeIntervalSince1970 - item.lastUpdate) / 60) > 10 ? "⚠︎ " : "")\(item.deviceName)")
                                    .font(.system(size: 11))
                                    .frame(height: 20, alignment: .center)
                                    .padding(.horizontal, 7)
                                Spacer()
                                if item.batteryLevel <= 10 {
                                    Text("\(item.batteryLevel)%") .font(.system(size: 11))
                                        .foregroundColor(.darkMyRed)
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
                            if index != 10 { Divider().padding(.top, -2) }
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

struct doubleRowBatteryWidgetEntryView: View {
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
                VStack(spacing: 17){
                    HStack(spacing: 23) {
                        ForEach(0..<4) { index in
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
                    HStack(spacing: 23) {
                        ForEach(0..<4) { index in
                            ZStack{
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
            } else {
                VStack(spacing: 17){
                    HStack(spacing: 23) {
                        ForEach(entry.data[0..<4], id: \.self) { item in
                            VStack(spacing: 17){
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
                                                .foregroundColor(Color(getPowerColor(item)))
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
                                                .foregroundColor(Color(getPowerColor(item)))
                                        }.rotationEffect(Angle(degrees: 129.6))
                                        Image(getDeviceIcon(item))
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            //sf.foregroundColor(.blackWhite)
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
                                                .foregroundColor(item.batteryLevel == 100 ? .myGreen : .primary)
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
                    HStack(spacing: 23) {
                        ForEach(entry.data[4..<8], id: \.self) { item in
                            VStack(spacing: 17){
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
                                                .foregroundColor(Color(getPowerColor(item)))
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
                                                .foregroundColor(Color(getPowerColor(item)))
                                        }.rotationEffect(Angle(degrees: 129.6))
                                        
                                        Image(getDeviceIcon(item))
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            //.foregroundColor(.blackWhite)
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
                                                .foregroundColor(item.batteryLevel == 100 ? .myGreen : .primary)
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
}

struct singleBatteryWidgetEntryView: View {
    var entry: ViewSizeTimelineProvider.Entry
    var item: Device?
    var deviceName: String
    var warringText: String
    private let lineWidth = 10.0
    
    var body: some View {
        if !entry.mainApp{
            Text("AirBattery is not running\nLaunch the app to make\nthe widget work")
                .multilineTextAlignment(.center)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.gray)
        } else {
            if let item = item {
                VStack(spacing: 10) {
                    ZStack{
                        Group {
                            Group {
                                Circle()
                                    .trim(from: 0.0, to: 0.8)
                                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                    .opacity(0.15)
                                Circle()
                                    .trim(from: CGFloat(abs((min(Double(item.batteryLevel)/100.0*0.8, 0.8))-0.001)), to: CGFloat(abs((min(Double(item.batteryLevel)/100.0*0.8, 0.8))-0.0005)))
                                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                    .foregroundColor(Color(getPowerColor(item)))
                                    .shadow(color: .black, radius: lineWidth*0.76, x: 0, y: 0)
                                    .clipShape(
                                        Circle()
                                            .trim(from: 0.0, to: 0.8)
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                    )
                                    .opacity(item.batteryLevel == 100 ? 0 : 1)
                                Circle()
                                    .trim(from: 0.0, to: Double(item.batteryLevel)/100.0*0.8)
                                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                    .foregroundColor(Color(getPowerColor(item)))
                            }.rotationEffect(Angle(degrees: 126))
                            Image(getDeviceIcon(item))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50, alignment: .center)
                            if item.isCharging != 0 || item.acPowered {
                                Image("batt_bolt_mask")
                                    .interpolation(.high)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, alignment: .center)
                                    .blendMode(.destinationOut)
                                    .offset(y: -55.5)
                                Image("batt_bolt")
                                    .interpolation(.high)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, alignment: .center)
                                    .foregroundColor(item.batteryLevel == 100 ? .myGreen : .primary)
                                    .offset(y: -55.5)
                            }
                        }.frame(width: 110, height: 110, alignment: .center)
                        Text(item.hasBattery ? "\(item.batteryLevel)%" : "")
                            .font(.system(size: 17))
                            .offset(x: 1, y: 47)
                    }.compositingGroup()
                    Text(item.deviceName)
                        .font(.system(size: 12))
                        .frame(width: 144, alignment: .center)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }.offset(y: item.isCharging != 0 ? 5 : 3.5)
            } else {
                VStack(spacing: 10) {
                    ZStack{
                        Circle()
                            .trim(from: 0.0, to: 0.8)
                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                            .frame(width: 110, height: 110, alignment: .center)
                            .rotationEffect(Angle(degrees: 126))
                            .opacity(0.15)
                        Text("     ")
                            .font(.system(size: 17))
                            .offset(x: 1, y: 47)
                    }
                    Text(deviceName == "" ? warringText : "Searching: ".local + deviceName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.6))
                        .frame(width: 150, alignment: .center)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }.offset(y: 3.5)
            }
        }
    }
}

struct batteryWidgetEntryView2: View {
    var entry: ViewSizeTimelineProvider.Entry
    
    var body: some View {
        VStack {
            switch entry.family {
            case .systemSmall:
                if #available(macOS 14, *) {
                    let item = entry.deviceName != "" ? entry.data.first(where: { $0.deviceName == entry.deviceName }) : nil
                    singleBatteryWidgetEntryView(entry: entry, item: item, deviceName: entry.deviceName, warringText: "Right click to configure".local)
                } else {
                    let deviceName = AirBatteryModel.singleDeviceName()
                    let item = deviceName != "" ? entry.data.first(where: { $0.deviceName == deviceName }) : nil
                    singleBatteryWidgetEntryView(entry: entry, item: item, deviceName: deviceName, warringText: "Select a Device in Preferences".local)
                }
            case .systemMedium:
                doubleRowBatteryWidgetEntryView(entry: entry)
            case .systemLarge:
                LargeWidgetView2(entry: entry)
            case .systemExtraLarge:
                EmptyView()
            @unknown default:
                EmptyView()
            }
        }.widgetURL(URL(string: "airbattery://reloadwingets"))
    }
}

@available(macOS 14, *)
struct batteryWidget2New: Widget {
    let kind: String = "widget.battery.part3"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: ViewSizeTimelineProviderNew()) { entry in
            batteryWidgetEntryView2(entry: entry)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .widgetBackground(Color("WidgetBackground"))
        }
        .configurationDisplayName("Batteries")
        .description("Displays the battery usage of a specific device")
        .disableContentMarginsIfNeeded()
        .supportedFamilies([.systemSmall])
    }
}

struct batteryWidget2: Widget {
    let kind: String = "widget.battery.part2"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ViewSizeTimelineProvider()) { entry in
            batteryWidgetEntryView2(entry: entry)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .widgetBackground(Color("WidgetBackground"))
        }
        .configurationDisplayName("Batteries")
        .description("More ways to displays battery usage for your devices")
        .disableContentMarginsIfNeeded()
        .supportFamily()
    }
}
