//
//  ContentView.swift
//  DockBattery
//
//  Created by apple on 2023/9/4.
//

import SwiftUI

let themeTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
let batteryTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
//let weatherTimer = Timer.publish(every: 660, on: .main, in: .common).autoconnect()

struct InitView: View {
    @AppStorage("dockTheme") var dockTheme = "battery"
    @AppStorage("weatherMode") var weatherMode = "off"
    @AppStorage("showOn") var showOn = "dock"
    @State var statusBarItem: NSStatusItem
    
    var body: some View {
        ZStack {
            if dockTheme == "multinfo"{
                MultiInfoView(fromDock: true)
            }else{
                MultiBatteryView()
            }
        }
        .onReceive(themeTimer){ _ in
            NSApp.dockTile.display()
            let windows = NSApplication.shared.windows
            for w in windows { if w.title != "Item-0" && w.level != .floating { w.level = .floating } }
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
        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        //BatteryView()
        MultiInfoView(fromDock: false)
        SettingsView()
    }
}
