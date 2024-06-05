//
//  DoubleBatteryWidget.swift
//  AirBatteryWidgetExtension
//
//  Created by apple on 2024/2/20.
//

import WidgetKit
import SwiftUI

struct doubleBatteryWidgetEntryView : View {
    var entry: ViewSizeTimelineProvider.Entry
    let lineWidth = 6.0
    
    var body: some View {
        if !entry.mainApp{
            Text("AirBattery is not running\nLaunch the app to make the widget work.")
                .multilineTextAlignment(.center)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.gray)
        } else {
            if entry.data.count == 0 {
                VStack(spacing: 17){
                    HStack(spacing: 23) {
                        ForEach(0..<4) { index in
                            Circle()
                                .stroke(lineWidth: lineWidth)
                                .frame(width: 58, alignment: .center)
                        }
                    }
                    HStack(spacing: 23) {
                        ForEach(0..<4) { index in
                            Circle()
                                .stroke(lineWidth: lineWidth)
                                .frame(width: 58, alignment: .center)
                        }
                    }
                }.opacity(0.15)
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
                                            //sf.foregroundColor(Color("black_white"))
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
                                        .offset(x: 1, y: 24)
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
}

struct singleBatteryWidgetEntryView : View {
    var entry: ViewSizeTimelineProvider.Entry
    var item: Device?
    let lineWidth = 10.0
    
    var body: some View {
        if !entry.mainApp{
            Text("AirBattery is not running\nLaunch the app to make\nthe widget work.")
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
                                    .foregroundColor(Color(getPowerColor(item.batteryLevel)))
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
                                    .foregroundColor(Color(getPowerColor(item.batteryLevel)))
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
                                    .foregroundColor(item.batteryLevel == 100 ? Color("my_green") : Color.primary)
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
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: lineWidth)
                            .frame(width: 104, alignment: .center)
                            .opacity(0.15)
                        HStack(spacing: 5) {
                            Image("blank")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 18, height: 18, alignment: .center)
                                .offset(y: 0.5)
                            Text("    ")
                                .font(.system(size: 25))
                        }
                    }.offset(y: 0.5)
                    let devicename = AirBatteryModel.singleDeviceName()
                    Text(devicename == "@@@@@@@@@@@@@@@@@@@@" ? "Select a Device in Preferences".local : "Searching for ".local + devicename)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.gray)
                        .frame(width: 154, alignment: .center)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .opacity(0.15)
                }
                .offset(y: 2)
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
                let item = entry.data.first(where: { $0.deviceName == AirBatteryModel.singleDeviceName() })
                singleBatteryWidgetEntryView(entry: entry, item: item)
            case .systemMedium:
                doubleBatteryWidgetEntryView(entry: entry)
            case .systemLarge:
                EmptyView()
            case .systemExtraLarge:
                EmptyView()
            @unknown default:
                EmptyView()
            }
        }
    }
}

struct doubleBatteryWidget: Widget {
    let kind: String = "widget.doubleBattery"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ViewSizeTimelineProvider()) { entry in
            batteryWidgetEntryView2(entry: entry)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .widgetBackground(Color("WidgetBackground"))
        }
        .configurationDisplayName("Batteries")
        .description("Displays battery information for your devices from AirBattery.")
        .disableContentMarginsIfNeeded()
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
        ])
    }
}
