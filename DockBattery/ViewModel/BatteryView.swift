//
//  BatteryView.swift
//  DockBattery
//
//  Created by apple on 2023/9/7.
//
/*
import SwiftUI

struct BatteryView: View {
    @State private var lineWidth = 9.0
    @State private var darkMode = getDarkMode()
    @State private var ibStatus = getPowerState()
    
    @AppStorage("appearance") var appearance = "auto"
    @AppStorage("timeLeft") var timeLeft = "false"
    
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
            Group{
                Circle()
                    .stroke(lineWidth: lineWidth)
                    .opacity(darkMode ? 0.2 : 0.13)
                    .foregroundColor(darkMode ? .white : .black)
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(Double(ibStatus.batteryLevel)/100.0, 0.5)))
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color(getPowerColor(ibStatus.batteryLevel)))
                    .rotationEffect(Angle(degrees: 270.0))
                Circle()
                    .trim(from: CGFloat(abs((min(Double(ibStatus.batteryLevel)/100.0, 1.0))-0.001)), to: CGFloat(abs((min(Double(ibStatus.batteryLevel)/100.0, 1.0))-0.0005)))
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color(getPowerColor(ibStatus.batteryLevel)))
                    .shadow(color: .black, radius: lineWidth*0.76, x: 0, y: 0)
                    .rotationEffect(Angle(degrees: 270.0))
                    .clipShape(Circle().stroke(lineWidth: lineWidth))
                Circle()
                    .trim(from: ibStatus.batteryLevel > 50 ? 0.25 : 0, to: CGFloat(min(Double(ibStatus.batteryLevel)/100.0, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color(getPowerColor(ibStatus.batteryLevel)))
                    .rotationEffect(Angle(degrees: 270.0))
            }
            .frame(width: 78, height: 78, alignment: .center)
            
            if ibStatus.hasBattery{
                if ibStatus.isCharging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 30))
                        .foregroundColor(darkMode ? .white : .black)
                        .scaleEffect(0.5)
                        .frame(height: 80, alignment: .top)
                }else if ibStatus.acPowered {
                    Image("powerplug.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .rotationEffect(Angle(degrees: -90))
                        .foregroundColor(darkMode ? .white : .black)
                        .scaleEffect(0.5)
                        .frame(width: 34, height: 66, alignment: .top)
                }
                
                VStack(spacing: 0){
                    HStack(spacing: 0){
                        Text(String(Int(ibStatus.batteryLevel)))
                            .foregroundColor(darkMode ? .white : .black)
                            .font(.custom("Helvetica-Bold", size: ibStatus.batteryLevel>99 ? 56 : 66))
                            .frame(width: ibStatus.batteryLevel>99 ? 94 : 74, alignment: .trailing)
                        Text("%").font(.custom("Helvetica-Bold", size: ibStatus.batteryLevel>99 ? 30 : 36))
                            .foregroundColor(darkMode ? .white : .black)
                            .offset(x:0, y:7)
                            .frame(width: 34, alignment: .leading)
                    }
                    if timeLeft.boolValue {
                        Text(ibStatus.timeLeft).font(.custom("Helvetica-Bold", size: (ibStatus.timeLeft == "∞" || ibStatus.timeLeft == "…") ? 40 : 30))
                            .foregroundColor(darkMode ? .white : .black)
                            .offset(x:-3, y:-6)
                            .frame(width: 94, alignment: .center)
                    }
                }
                .scaleEffect(0.5)
                .offset(x:2.4, y:timeLeft.boolValue ? ((ibStatus.timeLeft == "∞" || ibStatus.timeLeft == "…") ? 13 : 10) : 3.5)
            }else{
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.custom("Helvetica", size: 80))
                    .foregroundColor(Color("yellow"))
                    .scaleEffect(0.5)
                    .offset(y:-4)
            }
        }
        .onReceive(themeTimer) { t in darkMode = getDarkMode() }
        .onReceive(batteryTimer) { t in ibStatus = getPowerState() }
    }
}
*/
