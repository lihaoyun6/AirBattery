//
//  BatteryWidget3.swift
//  AirBattery
//
//  Created by apple on 2024/6/8.
//

import WidgetKit
import SwiftUI

struct batteryWidgetEntryView3 : View {
    var entry: ViewSizeTimelineProvider.Entry
    
    var body: some View {
        VStack {
            switch entry.family {
            case .systemSmall:
                SmallWidgetView2(entry: entry)
            case .systemMedium:
                doubleBatteryWidgetEntryView2(entry: entry)
            case .systemLarge:
                EmptyView()
            case .systemExtraLarge:
                EmptyView()
            @unknown default:
                EmptyView()
            }
        }.widgetURL(URL(string: "airbattery://reloadwingets"))
    }
}

struct SmallWidgetView2: View {
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
                            Circle()
                                .stroke(lineWidth: lineWidth)
                                .opacity(0.15)
                        }
                    }
                    HStack(spacing: 17) {
                        ForEach(0..<2) { index in
                            Circle()
                                .stroke(lineWidth: lineWidth)
                                .opacity(0.15)
                        }
                    }
                }
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
                                        .foregroundColor(Color(getPowerColor(item)))
                                        .rotationEffect(Angle(degrees: 270.0))
                                    Circle()
                                        .trim(from: CGFloat(abs((min(Double(item.batteryLevel)/100.0, 1.0))-0.001)), to: CGFloat(abs((min(Double(item.batteryLevel)/100.0, 1.0))-0.0005)))
                                        .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                        .foregroundColor(Color(getPowerColor(item)))
                                        .shadow(color: .black, radius: lineWidth*0.76, x: 0, y: 0)
                                        .rotationEffect(Angle(degrees: 270.0))
                                        .clipShape( Circle().stroke(lineWidth: lineWidth) )
                                    Circle()
                                        .trim(from: item.batteryLevel > 50 ? 0.25 : 0, to: CGFloat(min(Double(item.batteryLevel)/100.0, 1.0)))
                                        .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                        .foregroundColor(Color(getPowerColor(item)))
                                        .rotationEffect(Angle(degrees: 270.0))
                                    
                                    Image(getDeviceIcon(item))
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
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
                                        .foregroundColor(Color(getPowerColor(item)))
                                        .rotationEffect(Angle(degrees: 270.0))
                                    Circle()
                                        .trim(from: CGFloat(abs((min(Double(item.batteryLevel)/100.0, 1.0))-0.001)), to: CGFloat(abs((min(Double(item.batteryLevel)/100.0, 1.0))-0.0005)))
                                        .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                        .foregroundColor(Color(getPowerColor(item)))
                                        .shadow(color: .black, radius: lineWidth*0.76, x: 0, y: 0)
                                        .rotationEffect(Angle(degrees: 270.0))
                                        .clipShape( Circle().stroke(lineWidth: lineWidth) )
                                    Circle()
                                        .trim(from: item.batteryLevel > 50 ? 0.25 : 0, to: CGFloat(min(Double(item.batteryLevel)/100.0, 1.0)))
                                        .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                        .foregroundColor(Color(getPowerColor(item)))
                                        .rotationEffect(Angle(degrees: 270.0))
                                    
                                    Image(getDeviceIcon(item))
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
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
                            }.compositingGroup()
                        }
                    }
                }
            }
        }
    }
}

struct doubleBatteryWidgetEntryView2: View {
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
                                        Circle()
                                            .stroke(lineWidth: lineWidth)
                                            .opacity(0.15)
                                        Circle()
                                            .trim(from: 0.0, to: CGFloat(min(Double(item.batteryLevel)/100.0, 0.5)))
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(Color(getPowerColor(item)))
                                            .rotationEffect(Angle(degrees: 270.0))
                                        Circle()
                                            .trim(from: CGFloat(abs((min(Double(item.batteryLevel)/100.0, 1.0))-0.001)), to: CGFloat(abs((min(Double(item.batteryLevel)/100.0, 1.0))-0.0005)))
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(Color(getPowerColor(item)))
                                            .shadow(color: .black, radius: lineWidth*0.76, x: 0, y: 0)
                                            .rotationEffect(Angle(degrees: 270.0))
                                            .clipShape( Circle().stroke(lineWidth: lineWidth) )
                                        Circle()
                                            .trim(from: item.batteryLevel > 50 ? 0.25 : 0, to: CGFloat(min(Double(item.batteryLevel)/100.0, 1.0)))
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(Color(getPowerColor(item)))
                                            .rotationEffect(Angle(degrees: 270.0))
                                        
                                        Image(getDeviceIcon(item))
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
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
                                }.compositingGroup()
                            }
                        }
                    }
                    HStack(spacing: 23) {
                        ForEach(entry.data[4..<8], id: \.self) { item in
                            VStack(spacing: 17){
                                ZStack{
                                    Group {
                                        Circle()
                                            .stroke(lineWidth: lineWidth)
                                            .opacity(0.15)
                                        Circle()
                                            .trim(from: 0.0, to: CGFloat(min(Double(item.batteryLevel)/100.0, 0.5)))
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(Color(getPowerColor(item)))
                                            .rotationEffect(Angle(degrees: 270.0))
                                        Circle()
                                            .trim(from: CGFloat(abs((min(Double(item.batteryLevel)/100.0, 1.0))-0.001)), to: CGFloat(abs((min(Double(item.batteryLevel)/100.0, 1.0))-0.0005)))
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(Color(getPowerColor(item)))
                                            .shadow(color: .black, radius: lineWidth*0.76, x: 0, y: 0)
                                            .rotationEffect(Angle(degrees: 270.0))
                                            .clipShape( Circle().stroke(lineWidth: lineWidth) )
                                        Circle()
                                            .trim(from: item.batteryLevel > 50 ? 0.25 : 0, to: CGFloat(min(Double(item.batteryLevel)/100.0, 1.0)))
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(Color(getPowerColor(item)))
                                            .rotationEffect(Angle(degrees: 270.0))
                                        
                                        Image(getDeviceIcon(item))
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
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
                                }.compositingGroup()
                            }
                        }
                    }
                }
            }
        }
    }
}

struct batteryWidget3: Widget {
    let kind: String = "widget.battery.part4"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ViewSizeTimelineProvider()) { entry in
            batteryWidgetEntryView3(entry: entry)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .widgetBackground(Color("WidgetBackground"))
        }
        .configurationDisplayName("Batteries")
        .description("Displays battery usage for your devices without percentage")
        .disableContentMarginsIfNeeded()
        .supportedFamilies([.systemMedium, .systemSmall])
    }
}
