//
//  ContentView.swift
//  DockBattery
//
//  Created by apple on 2023/9/4.
//

import SwiftUI

let themeTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
let batteryTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
let weatherTimer = Timer.publish(every: 660, on: .main, in: .common).autoconnect()

/*class AppStorageManager: ObservableObject {
    @AppStorage("dockTheme") var dockTheme = "battery"
    @AppStorage("weatherMode") var weatherMode = "off"
    @AppStorage("appearance") var appearance = "auto"
    @AppStorage("timeLeft") var timeLeft = "false"
    @AppStorage("multiInfoMainBattery") var multiInfoMainBattery = "@MacInternalBattery"
    @AppStorage("forceWeather") var forceWeather = false
    @AppStorage("machineName") var machineName = "Mac"
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateValue), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    @objc func updateValue() {
        objectWillChange.send()
    }
}*/

struct InitView: View {
    @AppStorage("dockTheme") var dockTheme = "battery"
    @AppStorage("weatherMode") var weatherMode = "off"
    //@StateObject var settings = AppStorageManager()
    
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
        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        BatteryView()
        MultiInfoView(fromDock: false)
        //MultiInfoPlusView()
        SettingsView()
    }
}
