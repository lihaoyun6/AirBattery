//
//  BatteryInfo.swift
//  DockBattery
//
//  Created by apple on 2023/9/7.
//

import Foundation
import IOKit.ps

func getPowerState() -> iBattery {
    let internalFinder = InternalFinder()
    if let internalBattery = internalFinder.getInternalBattery() {
        let level = internalBattery.currentCapacity ?? 0
        return iBattery(hasBattery: true, isCharging: internalBattery.isCharging ?? false, isCharged :internalBattery.isCharged ?? false, acPowered: internalBattery.acPowered ?? false, timeLeft: internalBattery.timeLeft, batteryLevel: level)
    }
    return iBattery(hasBattery: false, isCharging: false, isCharged: false, acPowered: false, timeLeft: "", batteryLevel: 0)
}

func getPowerColor(_ level: Int, emoji: Bool = false) -> String {
    var colorName = "green"
    var colorEmoji = "🟩"
    if level <= 10 {
        colorName = "red"
        colorEmoji = "🟥"
    } else if level <= 20 {
        colorName = "yellow"
        colorEmoji = "🟨"
    }
    if emoji { return colorEmoji }
    return colorName
}

struct iBattery {
    var hasBattery: Bool
    var isCharging: Bool
    var isCharged: Bool
    var acPowered: Bool
    var timeLeft: String
    var batteryLevel: Int
    //var circleColor: Color
}

class InternalBattery {
    var name: String?
    var timeToFull: Int?
    var timeToEmpty: Int?
    var manufacturer: String?
    var manufactureDate: Date?
    var currentCapacity: Int?
    var maxCapacity: Int?
    var designCapacity: Int?
    var cycleCount: Int?
    var designCycleCount: Int?
    var acPowered: Bool?
    var isCharging: Bool?
    var isCharged: Bool?
    var amperage: Int?
    var voltage: Double?
    var watts: Double?
    var temperature: Double?

    var charge: Double? {
        get {
            if let current = self.currentCapacity,
               let max = self.maxCapacity {
                return (Double(current) / Double(max)) * 100.0
            }
            return nil
        }
    }

    var health: Double? {
        get {
            if let design = self.designCapacity,
               let current = self.maxCapacity {
                return (Double(current) / Double(design)) * 100.0
            }
            return nil
        }
    }

    var timeLeft: String {
        get {
            if let isCharging = self.isCharging {
                if let isCharged = self.isCharged { if isCharged { return "∞" } }
                if let minutes = isCharging ? self.timeToFull : self.timeToEmpty {
                    if minutes <= 0 {
                        return "…"
                    }
                    return String(format: "%.2d:%.2d", minutes / 60, minutes % 60)
                }
            }
            return "…"
        }
    }

    var timeRemaining: Int? {
        get {
            if let isCharging = self.isCharging {
                return isCharging ? self.timeToFull : self.timeToEmpty
            }
            return nil
        }
    }
}

class InternalFinder {
    private var serviceInternal: io_connect_t = 0 // io_object_t
    private var internalChecked: Bool = false
    private var hasInternalBattery: Bool = false

    public init() { }

    public var batteryPresent: Bool {
        get {
            if !self.internalChecked {
                let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
                let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array

                self.hasInternalBattery = sources.count > 0
                self.internalChecked = true
            }

            return self.hasInternalBattery
        }
    }

    fileprivate func open() {
        self.serviceInternal = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleSmartBattery"))
    }

    fileprivate func close() {
        IOServiceClose(self.serviceInternal)
        IOObjectRelease(self.serviceInternal)

        self.serviceInternal = 0
    }

    func getInternalBattery() -> InternalBattery? {
        self.open()

        if self.serviceInternal == 0 {
            return nil
        }

        let battery = self.getBatteryData()

        self.close()

        return battery
    }

    fileprivate func getBatteryData() -> InternalBattery {
        let battery = InternalBattery()

        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array

        for ps in sources {
            // Fetch the information for a given power source out of our snapshot
            let info = IOPSGetPowerSourceDescription(snapshot, ps).takeUnretainedValue() as! Dictionary<String, Any>

            // Pull out the name and capacity
            battery.name = info[kIOPSNameKey] as? String

            battery.timeToEmpty = info[kIOPSTimeToEmptyKey] as? Int
            battery.timeToFull = info[kIOPSTimeToFullChargeKey] as? Int
        }

        // Capacities
        battery.currentCapacity = self.getIntValue("CurrentCapacity" as CFString)
        battery.maxCapacity = self.getIntValue("MaxCapacity" as CFString)
        battery.designCapacity = self.getIntValue("DesignCapacity" as CFString)

        // Battery Cycles
        battery.cycleCount = self.getIntValue("CycleCount" as CFString)
        battery.designCycleCount = self.getIntValue("DesignCycleCount9C" as CFString)

        // Plug
        battery.acPowered = self.getBoolValue("ExternalConnected" as CFString)
        battery.isCharging = self.getBoolValue("IsCharging" as CFString)
        battery.isCharged = self.getBoolValue("FullyCharged" as CFString)

        // Power
        battery.amperage = self.getIntValue("Amperage" as CFString)
        battery.voltage = self.getVoltage()

        // Various
        battery.temperature = self.getTemperature()

        // Manufaction
        battery.manufacturer = self.getStringValue("Manufacturer" as CFString)
        battery.manufactureDate = self.getManufactureDate()

        if let amperage = battery.amperage,
           let volts = battery.voltage, let isCharging = battery.isCharging {
            let factor: CGFloat = isCharging ? 1 : -1
            let watts: CGFloat = (CGFloat(amperage) * CGFloat(volts)) / 1000.0 * factor

            battery.watts = Double(watts)
        }

        return battery
    }

    fileprivate func getIntValue(_ identifier: CFString) -> Int? {
        if let value = IORegistryEntryCreateCFProperty(self.serviceInternal, identifier, kCFAllocatorDefault, 0) {
            return value.takeRetainedValue() as? Int
        }

        return nil
    }

    fileprivate func getStringValue(_ identifier: CFString) -> String? {
        if let value = IORegistryEntryCreateCFProperty(self.serviceInternal, identifier, kCFAllocatorDefault, 0) {
            return value.takeRetainedValue() as? String
        }

        return nil
    }

    fileprivate func getBoolValue(_ forIdentifier: CFString) -> Bool? {
        if let value = IORegistryEntryCreateCFProperty(self.serviceInternal, forIdentifier, kCFAllocatorDefault, 0) {
            return value.takeRetainedValue() as? Bool
        }

        return nil
    }

    fileprivate func getTemperature() -> Double? {
        if let value = IORegistryEntryCreateCFProperty(self.serviceInternal, "Temperature" as CFString, kCFAllocatorDefault, 0) {
            return value.takeRetainedValue() as! Double / 100.0
        }

        return nil
    }

    fileprivate func getDoubleValue(_ identifier: CFString) -> Double? {
        if let value = IORegistryEntryCreateCFProperty(self.serviceInternal, identifier, kCFAllocatorDefault, 0) {
            return value.takeRetainedValue() as? Double
        }

        return nil
    }

    fileprivate func getVoltage() -> Double? {
        if let value = getDoubleValue("Voltage" as CFString) {
            return value / 1000.0
        }

        return nil
    }

    fileprivate func getManufactureDate() -> Date? {
        if let value = IORegistryEntryCreateCFProperty(self.serviceInternal, "ManufactureDate" as CFString, kCFAllocatorDefault, 0) {
            let date = value.takeRetainedValue() as! Int

            let day = date & 31
            let month = (date >> 5) & 15
            let year = ((date >> 9) & 127) + 1980

            var components = DateComponents()
            components.calendar = Calendar.current
            components.day = day
            components.month = month
            components.year = year

            return components.date
        }

        return nil
    }
}

