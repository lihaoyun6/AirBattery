//
//  AppIntent.swift
//  AirBattery
//
//  Created by apple on 2024/6/6.
//

import WidgetKit
import AppIntents

@available(macOS 14.0, *)
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Configuration"
    nonisolated(unsafe) static var description = IntentDescription("AirBattery battery usage widget")
    
    @Parameter(title: LocalizedStringResource("Enter Device Name"), default: "")
    var deviceName: String
    
    init(deviceName: String) {
        self.deviceName = deviceName
    }
    
    init() {
        self.deviceName = ""
    }
}
