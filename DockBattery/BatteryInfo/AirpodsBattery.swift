//
//  AirpodsBattery.swift
//  DockBattery
//
//  Created by apple on 2024/2/9.
//
//  =================================================
//  AirPods Pro/Beats BLE 常规广播数据包定义分析:
//  advertisementData长度 = 29bit
//  00~01: 制造商ID, 固定4c00
//  02~04: 未知
//  05~06: 设备型号ID:
//           0220 = Airpods
//           0e20 = Airpods Pro
//           0a20 = Airpods Max
//           0f20 = Airpods 2
//           1320 = Airpods 3
//           1420 = Airpods Pro 2
//           0320 = PowerBeats
//           0b20 = PowerBeats Pro
//           0c20 = Beats Solo Pro
//           1120 = Beats Studio Buds
//           1020 = Beats Flex
//           0520 = BeatsX
//           0620 = Beats Solo3
//           0920 = Beats Studio3
//           1720 = Beats Studio Pro
//           1220 = Beats Fit Pro
//           1620 = Beats Studio Buds+
//  07.1:  未知
//  07.2:  耳机取出状态:
//           5 = 两只耳机都在盒内
//           1 = 任意一只耳机被取出
//  08.1:  粗略电量(左耳):
//           0~10: x10 = 电量, f: 失联
//  08.2:  粗略电量(右耳):
//           0~10: x10 = 电量, f: 失联
//  09.1:  未知
//  09.2:  充电状态
//  10.1:  翻转指示
//  10.2:  未知
//  14:    左耳电量/充电指示
//           ff = 失联
//           <64(hex) = 未充电, 当前电量
//           >64(hex) = 在充电, 减80(hex)为当前电量
//  15:    右耳电量/充电指示
//           ff = 失联
//           <64(hex) = 未充电, 当前电量
//           >64(hex) = 电量(在充电, 减80(hex)为当前电量)
//  16:    充电盒电量/充电指示
//           ff = 失联
//           <64(hex) = 未在充电
//           >64(hex) = 在充电, 减80(hex)为当前电量
//  17~19: 未知
//  20~23: 未知
//  24~28: 未知
//  =================================================
//  AirPods Pro 2 BLE 合盖广播数据包定义分析:
//  advertisementData长度 = 25bit
//  00~01: 制造商ID, 固定4c00
//  02~03: 未知
//  04:    耳机取出状态:
//           24 = 双耳都在盒外
//           26 = 仅右耳被取出
//           2c = 仅左耳被取出
//           2e = 双耳都在盒内
//  05:    未知
//  06~10: 未知
//  11:    未知
//  12:    充电盒电量/充电指示
//           失联 = ff
//           <64(hex) = 电量(未在充电)
//           >64(hex) = 电量(在充电, 减80(hex)为当前电量)
//  13:    左耳电量/充电指示
//           被取出 = ff
//           >64(hex) = 电量(在充电, 减80(hex)为当前电量)
//  14:    右耳电量/充电指示
//           被取出 = ff
//           >64(hex) = 电量(在充电, 减80(hex)为当前电量)
//  15~20: 未知
//  21~22: 未知
//  23~24: 未知
//  =================================================
import SwiftUI
import Foundation
import CoreBluetooth

class AirpodsBattery: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @AppStorage("ideviceOverBLE") var ideviceOverBLE = false
    @AppStorage("cStatusOfIOB") var cStatusOfIOB = false
    var centralManager: CBCentralManager!
    var peripherals: [CBPeripheral?] = []
    var hotspotDevices: [String:UInt8] = [:]
    var scanTimer: Timer?
    //var mfgData: Data!
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() { scanTimer = Timer.scheduledTimer(timeInterval: 8.0, target: self, selector: #selector(scanDevices), userInfo: nil, repeats: true) }
    
    @objc func scanDevices() {
        //print("S \(Date().timeIntervalSince1970)")
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            //print("T \(Date().timeIntervalSince1970)")
            self.centralManager.stopScan()
        }
    }
    
    func stopScanning() {
        scanTimer?.invalidate()
        self.centralManager.stopScan()
    }
    
    func getModel(_ model: String) -> String {
        switch model {
        case "0220":
            return "Airpods"
        case "0e20":
            return "Airpods Pro"
        case "0a20":
            return "Airpods Max"
        case "0f20":
            return "Airpods 2"
        case "1320":
            return "Airpods 3"
        case "1420":
            return "Airpods Pro 2"
        case "0320":
            return "PowerBeats"
        case "0b20":
            return "PowerBeats Pro"
        case "0c20":
            return "Beats Solo Pro"
        case "1120":
            return "Beats Studio Buds"
        case "1020":
            return "Beats Flex"
        case "0520":
            return "BeatsX"
        case "0620":
            return "Beats Solo3"
        case "0920":
            return "Beats Studio3"
        case "1720":
            return "Beats Studio Pro"
        case "1220":
            return "Beats Fit Pro"
        case "1620":
            return "Beats Studio Buds+"
        default:
            return "Headphones"
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
                self.centralManager.stopScan()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // 获取个人热点广播数据
        if let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data, [16, 12].contains(data[2]), let deviceName = peripheral.name, ideviceOverBLE {
            if let device = AirBatteryModel.getByName(deviceName), let _ = device.deviceModel {
                if Double(Date().timeIntervalSince1970) - device.lastUpdate > 60 {
                    self.peripherals.append(peripheral)
                    self.centralManager.connect(peripheral, options: nil)
                }
             } else {
                 self.peripherals.append(peripheral)
                 self.centralManager.connect(peripheral, options: nil)
             }
        }
        
        if let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data, data.count == 25, data[0] == 76, let deviceName = peripheral.name {
            if data[2] == 18 {
                let deviceID = peripheral.identifier.uuidString
                let lastUpdate = Date().timeIntervalSince1970
                var subDevice:[Device] = []
                
                if let d = AirBatteryModel.getByName(deviceName + " (Case)"), (Double(lastUpdate) - d.lastUpdate) < 1 { return }
                
                var caseLevel = data[12]
                var caseCharging = 0
                if caseLevel != 255 {
                    caseCharging = caseLevel > 100 ? 1 : 0
                    caseLevel = (caseLevel ^ 128) & caseLevel
                }else{ caseLevel = getLevel(deviceName, "Case") }
                
                var leftLevel = data[13]
                var leftCharging = 0
                if leftLevel != 255 {
                    leftCharging = leftLevel > 100 ? 1 : 0
                    leftLevel = (leftLevel ^ 128) & leftLevel
                }else{ leftLevel = getLevel(deviceName, "Left") }
                
                var rightLevel = data[14]
                var rightCharging = 0
                if rightLevel != 255 {
                    rightCharging = rightLevel > 100 ? 1 : 0
                    rightLevel = (rightLevel ^ 128) & rightLevel
                }else{ rightLevel = getLevel(deviceName, "Right") }
                
                if leftLevel != 255 { subDevice.append(Device(deviceID: deviceID + "_Left", deviceType: "ap_pod_left", deviceName: deviceName + " 🄻", deviceModel: "Airpods Pro 2", batteryLevel: Int(leftLevel), isCharging: leftCharging, lastUpdate: lastUpdate)) }
                if rightLevel != 255 { subDevice.append(Device(deviceID: deviceID + "_Right", deviceType: "ap_pod_right", deviceName: deviceName + " 🅁", deviceModel: "Airpods Pro 2", batteryLevel: Int(rightLevel), isCharging: rightCharging, lastUpdate: lastUpdate)) }
                if leftLevel != 255 && rightLevel != 255 {
                    if (abs(Int(leftLevel) - Int(rightLevel)) < 3) && (leftCharging == rightCharging) {
                        subDevice = [Device(deviceID: deviceID + "_All", deviceType: "ap_pod_all", deviceName: deviceName + " 🄻🅁", deviceModel: "Airpods Pro 2", batteryLevel: Int(max(leftLevel, rightLevel)), isCharging: leftCharging, lastUpdate: lastUpdate)]
                    }
                }
                var mainDevice = Device(deviceID: deviceID, deviceType: "ap_case", deviceName: deviceName + " (Case)".local, deviceModel: "Airpods Pro 2", batteryLevel: Int(caseLevel), isCharging: caseCharging, lastUpdate: lastUpdate)
                if let d = AirBatteryModel.getByName(deviceName + " (Case)".local) {
                    mainDevice = d
                    mainDevice.deviceID = deviceID
                    mainDevice.deviceType = "ap_case"
                    mainDevice.deviceName = deviceName + " (Case)".local
                    mainDevice.deviceModel = "Airpods Pro 2"
                    mainDevice.batteryLevel = Int(caseLevel)
                    mainDevice.isCharging = caseCharging
                    mainDevice.lastUpdate = lastUpdate
                }
                mainDevice.subDevices = subDevice
                //print("合盖消息 [\(deviceName)@\(deviceID)]: \(data.hexEncodedString())")
                AirBatteryModel.updateBLEdevice(byName: true, mainDevice)
            }
        }
        
        if let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data, data.count == 29, data[0] == 76, let deviceName = peripheral.name {
            if data[2] == 7 {
                let deviceID = peripheral.identifier.uuidString
                let lastUpdate = Date().timeIntervalSince1970
                var subDevice:[Device] = []
                
                if let d = AirBatteryModel.getByName(deviceName + " (Case)"), (Double(lastUpdate) - d.lastUpdate) < 1 { return }
                
                let model = getModel(String(format: "%02x%02x", data[5], data[6]))
                
                var caseLevel = data[16]
                var caseCharging = 0
                if caseLevel != 255 {
                    caseCharging = caseLevel > 100 ? 1 : 0
                    caseLevel = (caseLevel ^ 128) & caseLevel
                }else{ caseLevel = getLevel(deviceName, "Case") }
                if caseLevel == 255 { return }
                
                var leftLevel = data[14]
                var leftCharging = 0
                if leftLevel != 255 {
                    leftCharging = leftLevel > 100 ? 1 : 0
                    leftLevel = (leftLevel ^ 128) & leftLevel
                }else{ leftLevel = getLevel(deviceName, "Left") }
                
                var rightLevel = data[15]
                var rightCharging = 0
                if rightLevel != 255 {
                    rightCharging = rightLevel > 100 ? 1 : 0
                    rightLevel = (rightLevel ^ 128) & rightLevel
                }else{ rightLevel = getLevel(deviceName, "Right") }
                
                if leftLevel != 255 { subDevice.append(Device(deviceID: deviceID + "_Left", deviceType: "ap_pod_left", deviceName: deviceName + " 🄻", deviceModel: model, batteryLevel: Int(leftLevel), isCharging: leftCharging, lastUpdate: lastUpdate)) }
                if rightLevel != 255 { subDevice.append(Device(deviceID: deviceID + "_Right", deviceType: "ap_pod_right", deviceName: deviceName + " 🅁", deviceModel: model, batteryLevel: Int(rightLevel), isCharging: rightCharging, lastUpdate: lastUpdate)) }
                if leftLevel != 255 && rightLevel != 255 {
                    if (abs(Int(leftLevel) - Int(rightLevel)) < 3) && (leftCharging == rightCharging) {
                        subDevice = [Device(deviceID: deviceID + "_All", deviceType: "ap_pod_all", deviceName: deviceName + " 🄻🅁", deviceModel: model, batteryLevel: Int(max(leftLevel, rightLevel)), isCharging: leftCharging, lastUpdate: lastUpdate)]
                    }
                }
                var mainDevice = Device(deviceID: deviceID, deviceType: "ap_case", deviceName: deviceName + " (Case)".local, deviceModel: model, batteryLevel: Int(caseLevel), isCharging: caseCharging, lastUpdate: lastUpdate)
                if let d = AirBatteryModel.getByName(deviceName + " (Case)".local) {
                    mainDevice = d
                    mainDevice.deviceID = deviceID
                    mainDevice.deviceType = "ap_case"
                    mainDevice.deviceName = deviceName + " (Case)".local
                    mainDevice.deviceModel = model
                    mainDevice.batteryLevel = Int(caseLevel)
                    mainDevice.isCharging = caseCharging
                    mainDevice.lastUpdate = lastUpdate
                }
                mainDevice.subDevices = subDevice
                //print("开盖消息 [\(deviceName)@\(deviceID)]: \(data.hexEncodedString())")
                AirBatteryModel.updateBLEdevice(byName: true, mainDevice)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        var clear = true
        if service.uuid == CBUUID(string: "180F") || service.uuid == CBUUID(string: "180A") {
            for characteristic in characteristics {
                if characteristic.uuid == CBUUID(string: "2A19") || characteristic.uuid == CBUUID(string: "2A24") {
                    clear = false
                    peripheral.readValue(for: characteristic)
                }
            }
        }
        if clear { if let index = self.peripherals.firstIndex(of: peripheral) { self.peripherals.remove(at: index) } }
        
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == CBUUID(string: "2A19"){
            if let data = characteristic.value {
                if let deviceName = peripheral.name{
                    let now = Date().timeIntervalSince1970
                    var charging = -1
                    if let lastLevel = hotspotDevices[deviceName], cStatusOfIOB {
                        //print(lastLevel, data[0])
                        if data[0] > lastLevel { charging = 1 }
                        if data[0] < lastLevel { charging = 0 }
                    }
                    hotspotDevices[deviceName] = data[0]
                    if let device = AirBatteryModel.getByName(deviceName) {
                        var d = device
                        //print("\(d.deviceName), \(d.isCharging)")
                        d.deviceID = peripheral.identifier.uuidString
                        d.batteryLevel = Int(data[0])
                        d.lastUpdate = now
                        if charging != -1 { d.isCharging = charging }
                        AirBatteryModel.updateIdevices(byName: true, d)
                    } else {
                        let d = Device(deviceID: peripheral.identifier.uuidString, deviceType: "general_bt", deviceName: deviceName, batteryLevel: Int(data[0]), isCharging: (charging != -1) ? charging : 0, lastUpdate: now)
                        AirBatteryModel.updateIdevices(byName: true, d)
                    }
                }
            }
        }
        
        if characteristic.uuid == CBUUID(string: "2A24") {
            if let data = characteristic.value, let model = data.ascii() {
                if !model.lowercased().contains("watch") {
                    if let deviceName = peripheral.name {
                        let now = Date().timeIntervalSince1970
                        if let device = AirBatteryModel.getByName(deviceName), device.deviceModel != model{
                            var d = device
                            d.deviceType = model.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "\\d", with: "", options: .regularExpression, range: nil)
                            d.deviceModel = model
                            d.lastUpdate = now
                            AirBatteryModel.updateIdevices(byName: true, d)
                            //print(d)
                        }
                    }
                }
            }
        }
        //self.centralManager.cancelPeripheralConnection(peripheral)
    }

    
    /*func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == CBUUID(string: "2A19") {
                peripheral.readValue(for: characteristic)
            }
        }
        if let index = self.peripherals.firstIndex(of: peripheral) { self.peripherals.remove(at: index) }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print(peripheral.identifier.uuidString)
        if characteristic.uuid == CBUUID(string: "2A19") { // 电池信息特征的 UUID
            if let data = characteristic.value {
                let batteryLevel = data[0]
                if let deviceName = peripheral.name{
                    if let device = AirBatteryModel.getByName(deviceName) {
                        var d = device
                        d.batteryLevel = Int(batteryLevel)
                        d.lastUpdate = Date().timeIntervalSince1970
                        AirBatteryModel.updateIdevices(byName: true, d)
                    } else {
                        let d = Device(deviceID: peripheral.identifier.uuidString, deviceType: "iPhone", deviceName: deviceName, batteryLevel: data[0], isCharging: 0, lastUpdate: now)
                        AirBatteryModel.updateIdevices(byName: true, d)
                    }
                }
            }
        }
        self.centralManager.cancelPeripheralConnection(peripheral)
    }*/
    
    func getLevel(_ name: String,_ side: String) -> UInt8{
        guard let result = process(path: "/usr/sbin/system_profiler", arguments: ["SPBluetoothDataType", "-json"]) else { return 255 }
        if let json = try? JSONSerialization.jsonObject(with: Data(result.utf8), options: []) as? [String: Any],
        let SPBluetoothDataTypeRaw = json["SPBluetoothDataType"] as? [Any],
        let SPBluetoothDataType = SPBluetoothDataTypeRaw[0] as? [String: Any],
        let device_connected = SPBluetoothDataType["device_connected"] as? [Any] {
            for device in device_connected{
                let d = device as! [String: Any]
                if let n = d.keys.first,n == name,let info = d[n] as? [String: Any] {
                    if let level = info["device_batteryLevel"+side] as? String {
                        return UInt8(level.replacingOccurrences(of: "%", with: "")) ?? 255
                    }
                }
            }
        }
        return 255
    }
}
