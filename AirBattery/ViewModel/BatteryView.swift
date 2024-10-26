//
//  BatteryView.swift
//  AirBattery
//
//  Created by apple on 2024/2/23.
//

import SwiftUI

struct BatteryView: View {
    var item: Device
    var body: some View {
        let width = round(max(1, min(19, Double(item.batteryLevel)/100*19)))
        ZStack{
            ZStack(alignment: .leading) {
                Image("batt_outline_bold")
                Group{
                    Rectangle()
                        .fill(Color(getPowerColor(item)))
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

struct mainBatteryView: View {
    @State var item: iBattery = InternalBattery.status
    //@State var item: iBattery = iBattery(hasBattery: true, isCharging: true, isCharged: false, acPowered: true, timeLeft: "", batteryLevel: 46)
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("hidePercentWhenFull") var hidePercentWhenFull = false
    @AppStorage("intBattOnStatusBar") var intBattOnStatusBar = true
    @AppStorage("colorfulBattery") var colorfulBattery = false
    @AppStorage("iosBatteryStyle") var iosBatteryStyle = false
    @AppStorage("batteryPercent") var batteryPercent = "outside"
    @AppStorage("internalLevel") var internalLevel = false
    @AppStorage("hideLevel") var hideLevel = 90
    
    var body: some View {
        HStack(alignment: .center, spacing:4){
            if item.hasBattery && intBattOnStatusBar {
                if batteryPercent == "outside" && !(hidePercentWhenFull && item.batteryLevel > hideLevel) {
                    Text("\(item.batteryLevel)%").font(.system(size: 11))
                }
                if !iosBatteryStyle {
                    let width = round(max(2, min(19, Double(item.batteryLevel)/100*19)))
                    ZStack(alignment: .leading){
                        ZStack(alignment: .leading) {
                            if colorfulBattery || batteryPercent == "inside" {
                                Image("batt_outline_bold")
                            } else {
                                Image("batt_outline")
                            }
                            if batteryPercent == "inside" && !(hidePercentWhenFull && item.batteryLevel > hideLevel) {
                                BatteryLevelView(item: item)
                                    .scaleEffect(0.9)
                                    .frame(width: 26)
                                    .foregroundColor(colorfulBattery ? Color(getPowerColor(ib2ab(item))) : .primary)
                                    .offset(x: item.batteryLevel < 100 ? -0.5 : 0)
                            } else {
                                Rectangle()
                                    .fill(colorfulBattery ? Color(getPowerColor(ib2ab(item))) : (item.batteryLevel <= 10 ? .red : .primary))
                                    .frame(width: width, height: 8, alignment: .leading)
                                    .clipShape(RoundedRectangle(cornerRadius: 1.5, style: .continuous))
                                    .offset(x:2)
                            }
                        }
                        if item.acPowered && batteryPercent != "inside" {
                            Image("batt_" + ((item.isCharging || item.isCharged) ? "bolt" : "plug") + "_mask")
                                .blendMode(.destinationOut)
                                .offset(x:6)
                            Image("batt_" + ((item.isCharging || item.isCharged) ? "bolt" : "plug"))
                                .offset(x:6)
                                .foregroundColor(Color("black_white"))
                        }
                    }.compositingGroup()
                } else {
                    ZStack {
                        Image("battery.100percent")
                            .resizable().scaledToFit()
                            .frame(width: 27)
                            .opacity(0.4)
                            .mask (
                                HStack {
                                    Spacer().frame(minWidth: 0)
                                    Rectangle().frame(width: min(25, CGFloat(100 - item.batteryLevel) / 100 * 27))
                                }
                            )
                        Image("battery.100percent")
                            .resizable().scaledToFit()
                            .foregroundColor(colorfulBattery ? Color(getPowerColor(ib2ab(item)) + "2") : (item.batteryLevel <= 10 ? .red : .primary))
                            .frame(width: 27)
                            .mask (
                                HStack {
                                    Rectangle().frame(width: max(2, CGFloat(item.batteryLevel) / 100 * 27))
                                    Spacer().frame(minWidth: 0)
                                }
                            )
                        if batteryPercent == "inside" && !(hidePercentWhenFull && item.batteryLevel > hideLevel) {
                            if colorfulBattery {
                                BatteryLevelView(item: item)
                                    .foregroundColor(.white)
                                    .frame(width: 27)
                            } else {
                                BatteryLevelView(item: item)
                                    .foregroundColor(.white)
                                    .blendMode(.destinationOut)
                                    .frame(width: 27)
                            }
                        } else {
                            if item.acPowered {
                                Image("batt_" + ((item.isCharging || item.isCharged) ? "bolt" : "plug") + "_mask")
                                    .blendMode(.destinationOut)
                                    .offset(x:-1.5)
                                Image("batt_" + ((item.isCharging || item.isCharged) ? "bolt" : "plug"))
                                    .offset(x:-1.5)
                                    .foregroundColor(Color("black_white"))
                            }
                        }
                    }.compositingGroup()
                }
            } else {
                Image("bolt.square.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            }
        }
        .onReceive(dockTimer) { t in refeshPinnedBar() }
        .onReceive(mainTimer) { t in
            if item.hasBattery {
                InternalBattery.status = getPowerState()
                let width = statusBarItem.button?.frame.size.width
                if intBattOnStatusBar {
                    item = InternalBattery.status
                    if batteryPercent != "outside" {
                        if width != 42 { setStatusBar(width: 42) }
                    } else {
                        if (hidePercentWhenFull && item.batteryLevel > hideLevel) {
                            if width != 42 { setStatusBar(width: 42) }
                        } else {
                            if width != 76 { setStatusBar(width: 76) }
                        }
                    }
                } else {
                    if width != 36 { setStatusBar(width: 36) }
                }
            }
        }
    }
}

struct BatteryLevelView: View {
    var item: iBattery
    
    var body: some View {
        HStack {
            if item.acPowered {
                HStack(spacing: item.batteryLevel > 99 ? -1 : -0.5) {
                    Text("\(item.batteryLevel)")
                        .font(.system(size: item.batteryLevel > 99 ? 10 : 11, weight: .medium))
                        .tracking(item.batteryLevel > 99 ? -0.5 : 0)
                    if item.isCharging || item.isCharged {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: item.batteryLevel > 99 ? 7 : 8, weight: .medium))
                    } else {
                        Image("batt_plug")
                            .resizable().scaledToFit()
                            .frame(width: 7)
                    }
                }.offset(x: -1)
            } else {
                Text("\(item.batteryLevel)")
                    .font(.system(size: item.batteryLevel > 99 ? 10 : 11, weight: .medium))
                    .offset(x: -1.5)
            }
        }
    }
}

func setStatusBar(width: Double) {
    let iconView = NSHostingView(rootView: mainBatteryView())
    iconView.frame = NSRect(x: 0, y: 0, width: width, height: 21.5)
    statusBarItem.button?.subviews.removeAll()
    statusBarItem.button?.addSubview(iconView)
    statusBarItem.button?.frame = iconView.frame
}
