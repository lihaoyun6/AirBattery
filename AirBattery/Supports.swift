//
//  Support.swift
//  AirBattery
//
//  Created by apple on 2024/2/9.
//
import SwiftUI
import CryptoKit
import SystemConfiguration
import UserNotifications

let widgetInterval = UserDefaults.standard.integer(forKey: "widgetInterval")
let updateInterval = UserDefaults.standard.double(forKey: "updateInterval")

let dockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
let alertTimer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()
let widgetDataTimer = Timer.publish(every: TimeInterval(24 * updateInterval), on: .main, in: .common).autoconnect()
let nearCastTimer = Timer.publish(every: TimeInterval(60 * updateInterval + Double(arc4random_uniform(10)) - Double(arc4random_uniform(10))), on: .main, in: .common).autoconnect()
let widgetViewTimer = Timer.publish(every: TimeInterval(60 * (widgetInterval != 0 ? Double(abs(widgetInterval)) : updateInterval)), on: .main, in: .common).autoconnect()
let macID = getMacModelIdentifier()
let isoFormatter = ISO8601DateFormatter()

struct dayAndWeek {
    var day: String
    var week: String
    var time: String
    var locale: String
}

extension View {
    func roundedCorners(radius: CGFloat, corners: RectCorner) -> some View {
        clipShape( RoundedCornersShape(radius: radius, corners: corners) )
    }
}

extension String {
    var boolValue: Bool { return (self as NSString).boolValue }
    var local: String { return NSLocalizedString(self, comment: "") }
}

extension NSMenuItem {
    func performAction() {
        guard let menu else {
            return
        }
        menu.performActionForItem(at: menu.index(of: self))
    }
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
    
    func ascii() -> String? {
        var asciiString = ""
        for byte in self {
            asciiString.append(Character(UnicodeScalar(byte)))
        }
        return asciiString.replacingOccurrences(of: "\0", with: "")
    }
}

struct RectCorner: OptionSet {
    
    let rawValue: Int
        
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomRight = RectCorner(rawValue: 1 << 2)
    static let bottomLeft = RectCorner(rawValue: 1 << 3)
    
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}


struct RoundedCornersShape: Shape {
    
    var radius: CGFloat = .zero
    var corners: RectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let p1 = CGPoint(x: rect.minX, y: corners.contains(.topLeft) ? rect.minY + radius  : rect.minY )
        let p2 = CGPoint(x: corners.contains(.topLeft) ? rect.minX + radius : rect.minX, y: rect.minY )

        let p3 = CGPoint(x: corners.contains(.topRight) ? rect.maxX - radius : rect.maxX, y: rect.minY )
        let p4 = CGPoint(x: rect.maxX, y: corners.contains(.topRight) ? rect.minY + radius  : rect.minY )

        let p5 = CGPoint(x: rect.maxX, y: corners.contains(.bottomRight) ? rect.maxY - radius : rect.maxY )
        let p6 = CGPoint(x: corners.contains(.bottomRight) ? rect.maxX - radius : rect.maxX, y: rect.maxY )

        let p7 = CGPoint(x: corners.contains(.bottomLeft) ? rect.minX + radius : rect.minX, y: rect.maxY )
        let p8 = CGPoint(x: rect.minX, y: corners.contains(.bottomLeft) ? rect.maxY - radius : rect.maxY )

        
        path.move(to: p1)
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY),
                    tangent2End: p2,
                    radius: radius)
        path.addLine(to: p3)
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY),
                    tangent2End: p4,
                    radius: radius)
        path.addLine(to: p5)
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
                    tangent2End: p6,
                    radius: radius)
        path.addLine(to: p7)
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
                    tangent2End: p8,
                    radius: radius)
        path.closeSubpath()

        return path
    }
}

public func process(path: String, arguments: [String], timeout: Double = 0) -> String? {
    let task = Process()
    task.launchPath = path
    task.arguments = arguments
    task.standardError = Pipe()
    
    let outputPipe = Pipe()
    defer { outputPipe.fileHandleForReading.closeFile() }
    task.standardOutput = outputPipe
    
    if timeout != 0 {
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(timeout)) {
            if task.isRunning {
                //print("⚠️ Process Timeout! Killed")
                //print("[\(path) \(arguments.joined(separator: " "))]")
                task.terminate()
            }
        }
    }
    
    do {
        try task.run()
    } catch let error {
        print("\(error.localizedDescription)")
        return nil
    }
    
    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(decoding: outputData, as: UTF8.self)
    
    if output.isEmpty { return nil }
    
    return output.trimmingCharacters(in: .newlines)
}

func createAlert(level: NSAlert.Style = .warning, title: String, message: String, button1: String, button2: String = "") -> NSAlert {
    let alert = NSAlert()
    alert.messageText = title.local
    alert.informativeText = message.local
    alert.addButton(withTitle: button1.local)
    if button2 != "" { alert.addButton(withTitle: button2.local) }
    alert.alertStyle = level
    return alert
}

func findParentKey(forValue value: Any, in json: [String: Any]) -> String? {
    for (key, subJson) in json {
        if let subJsonDictionary = subJson as? [String: Any] {
            if subJsonDictionary.values.contains(where: { $0 as? String == value as? String }) {
                return key
            } else if let parentKey = findParentKey(forValue: value, in: subJsonDictionary) {
                return parentKey
            }
        } else if let subJsonArray = subJson as? [[String: Any]] {
            for subJsonDictionary in subJsonArray {
                if subJsonDictionary.values.contains(where: { $0 as? String == value as? String }) {
                    return key
                } else if let parentKey = findParentKey(forValue: value, in: subJsonDictionary) {
                    return parentKey
                }
            }
        }
    }
    return nil
}

func randomString(type: Int = 1, length: Int) -> String {
    var characters = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    if type == 1 { characters = Array("abcdefghijklmnopqrstuvwxyz0123456789") }
    var randomString = ""

    for _ in 0..<length {
        if let randomCharacter = characters.randomElement() {
            randomString.append(randomCharacter)
        }
    }
    return randomString
}

func getPowerState() -> iBattery {
    @AppStorage("machineType") var machineType = "Mac"
    if !machineType.lowercased().contains("book") { return iBattery(hasBattery: false, isCharging: false, isCharged: false, acPowered: false, timeLeft: "", batteryLevel: 0) }
    let internalFinder = InternalFinder()
    if let internalBattery = internalFinder.getInternalBattery() {
        if let level = internalBattery.charge {
            var ib = iBattery(hasBattery: true, isCharging: internalBattery.isCharging ?? false, isCharged :internalBattery.isCharged ?? false, acPowered: internalBattery.acPowered ?? false, timeLeft: internalBattery.timeLeft, batteryLevel: Int(level))
            if #available(macOS 12.0, *) { ib.lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled }
            return ib
        }
    }
    return iBattery(hasBattery: false, isCharging: false, isCharged: false, acPowered: false, timeLeft: "", batteryLevel: 0)
}

func getPowerColor(_ device: Device) -> String {
    if device.lowPower { return "my_yellow" }
    
    var colorName = "my_green"
    if device.batteryLevel <= 10 {
        colorName = "my_red"
    } else if device.batteryLevel <= 20 {
        colorName = "my_yellow"
    }
    return colorName
}

func getDarkMode() -> Bool {
    @AppStorage("appearance") var appearance = "auto"
    return (appearance == "auto") ? NSApp.effectiveAppearance == NSAppearance(named: .darkAqua) : appearance.boolValue
}

func getMonoNum(_ num: Int, count: Int = 3, bold: Bool = false) -> String {
    let chars = bold ? ["𝟬","𝟭","𝟮","𝟯","𝟰","𝟱","𝟲","𝟳","𝟴","𝟵"] : ["𝟢","𝟣","𝟤","𝟥","𝟦","𝟧","𝟨","𝟩","𝟪","𝟫"]
    var output: [String] = []
    for i in String(num) { if let n = Int(String(i)) { output.append(chars[n]) } }
    return String(repeating: "  ", count: (count - output.count)) + output.joined()
}

func ib2ab(_ ib: iBattery) -> Device {
    @AppStorage("machineType") var machineType = "Mac"
    @AppStorage("deviceName") var deviceName = "Mac"
    return Device(hasBattery: ib.hasBattery, deviceID: "@MacInternalBattery", deviceType: "Mac", deviceName: deviceName, deviceModel: machineType, batteryLevel: ib.batteryLevel, isCharging: ib.isCharging ? 1 : 0, isCharged: ib.isCharged, acPowered: ib.acPowered, lowPower: ib.lowPower, lastUpdate: Double(Date().timeIntervalSince1970))
}

func sliceList(data: [Device], length: Int, count: Int) -> [Device] {
    let totalLength = length * count
    if totalLength <= data.count { return Array(data[totalLength-length..<totalLength]) }
    var list: [Device]
    if totalLength - length > data.count {
        list = []
    } else {
        list = Array(data[totalLength-length..<data.count])
    }
    if list != [] { while list.count < length { list.append(Device(hasBattery: false, deviceID: "", deviceType: "blank", deviceName: "", batteryLevel: 0, isCharging: 0, lastUpdate: 0)) } }
    return list
}

func copyToClipboard(_ text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
}

func pasteFromClipboard() -> String? {
    if let content = NSPasteboard.general.string(forType: .string) { return content }
    return nil
}

func isGroudIDValid(id: String) -> Bool {
    let pre = NSPredicate(format: "SELF MATCHES %@", "^[a-z0-9\\-]+$")
    let pre2 = NSPredicate(format: "SELF MATCHES %@", "^[a-zA-Z0-9\\-]+$")
    let ncid = pre.evaluate(with: String(id.prefix(15)))
    let pasd = pre2.evaluate(with: id)
    return (id.count == 23 && String(id.prefix(3)) == "nc-" && ncid && pasd)
}

func batteryAlert() {
    @AppStorage("alertLevel") var alertLevel = 10
    @AppStorage("fullyLevel") var fullyLevel = 100
    @AppStorage("alertSound") var alertSound = true
    let alertList = (UserDefaults.standard.object(forKey: "alertList") ?? []) as! [String]
    var allDevices = AirBatteryModel.getAll()
    let ibStatus = InternalBattery.status
    allDevices.insert(ib2ab(ibStatus), at: 0)
    for device in allDevices.filter({ $0.batteryLevel <= alertLevel && $0.isCharging == 0 && alertList.contains($0.deviceName) }) {
        let content = UNMutableNotificationContent()
        content.title = "Low Battery".local
        content.body = String(format: "\"%@\" remaining battery %d%%".local, device.deviceName, device.batteryLevel)
        content.sound = alertSound ? UNNotificationSound.default : nil
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: device.deviceName + ".lowbattery", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error { print("Notification failed to send：\(error.localizedDescription)") }
        }
    }
    for device in allDevices.filter({ $0.batteryLevel >= fullyLevel && $0.isCharging != 0 && alertList.contains($0.deviceName) }) {
        let content = UNMutableNotificationContent()
        content.title = "Fully Charged".local
        content.body = String(format: "\"%@\" battery has reached %d%%".local, device.deviceName, device.batteryLevel)
        content.sound = alertSound ? UNNotificationSound.default : nil
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: device.deviceName + ".fullycharged", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error { print("Notification failed to send：\(error.localizedDescription)") }
        }
    }
}

func getMacDeviceType() -> String {
    guard let result = process(path: "/usr/sbin/system_profiler", arguments: ["SPHardwareDataType", "-json"]) else { return "Mac" }
    if let json = try? JSONSerialization.jsonObject(with: Data(result.utf8), options: []) as? [String: Any],
       let SPHardwareDataTypeRaw = json["SPHardwareDataType"] as? [Any],
       let SPHardwareDataType = SPHardwareDataTypeRaw[0] as? [String: Any],
       let model = SPHardwareDataType["machine_name"] as? String{
        return model
    }
    return "Mac"
}

func getMacDeviceUUID() -> String? {
    let dev = IOServiceMatching("IOPlatformExpertDevice")
    let platformExpert: io_service_t = IOServiceGetMatchingService(kIOMasterPortDefault, dev)
    if platformExpert != 0 {
        if let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0)?.takeUnretainedValue() {
            IOObjectRelease(platformExpert)
            return serialNumberAsCFString as? String
        }
        IOObjectRelease(platformExpert)
    }
    return nil
}

func getMacModelIdentifier() -> String {
    var size = 0
    sysctlbyname("hw.model", nil, &size, nil, 0)
    var model = [CChar](repeating: 0,  count: Int(size))
    sysctlbyname("hw.model", &model, &size, nil, 0)
    if let modelString = String(validatingUTF8: model) {
        return modelString
    } else {
        return "unknow"
    }
}

func getMacDeviceName() -> String {
    @AppStorage("machineType") var machineType = "Mac"
    var computerName: CFString?
    if let dynamicStore = SCDynamicStoreCreate(nil, "GetComputerName" as CFString, nil, nil) {
        computerName = SCDynamicStoreCopyComputerName(dynamicStore, nil) as CFString?
    }
    if let name = computerName as String? { return name }
    return machineType
}

func getFirstNCharacters(of string: String, count: Int) -> String? {
    guard string.count >= count else { return nil }
    let index = string.index(string.startIndex, offsetBy: count)
    let substring = string[string.startIndex..<index]
    return String(substring)
}

func generateSymmetricKey(password: String) -> SymmetricKey {
    let pass = substring(from: password, start: 15, length: 8)
    let salt = String(password.prefix(15))
    let passwordData = Data(pass!.utf8)
    let saltData = salt.data(using: .utf8)!
    let derivedKey = HKDF<SHA256>.deriveKey(inputKeyMaterial: SymmetricKey(data: passwordData), salt: saltData, info: Data(), outputByteCount: 32)
    return derivedKey
}

func encryptString(_ string: String, password: String) -> String? {
    let key = generateSymmetricKey(password: password)
    let stringData = Data(string.utf8)
    
    do {
        let sealedBox = try AES.GCM.seal(stringData, using: key)
        return sealedBox.combined?.base64EncodedString()
    } catch {
        print("Encryption error: \(error)")
        return nil
    }
}

func decryptString(_ string: String, password: String) -> String? {
    let key = generateSymmetricKey(password: password)
    
    do {
        guard let data = Data(base64Encoded: string) else { return nil }
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        return String(data: decryptedData, encoding: .utf8)
    } catch {
        print("Decryption error: \(error)")
        return nil
    }
}

func substring(from string: String, start: Int, length: Int) -> String? {
    guard start >= 0, length > 0, start + length <= string.count else {
        return nil
    }

    let startIndex = string.index(string.startIndex, offsetBy: start)
    let endIndex = string.index(startIndex, offsetBy: length)
    let substring = string[startIndex..<endIndex]
    return String(substring)
}


func getFiles(withExtension fileExtension: String, in directory: URL) -> [URL] {
    let fileManager = FileManager.default
    
    do {
        let filesAndDirectories = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [])
        let filteredFiles = filesAndDirectories.filter { $0.pathExtension == fileExtension }
        return filteredFiles
    } catch {
        print("Failed to get contents of directory: \(error)")
        return []
    }
}

func getHeadphoneModel(_ model: String) -> String {
    switch model {
    case "2002":
        return "Airpods"
    case "200e":
        return "Airpods Pro"
    case "200a":
        return "Airpods Max"
    case "200f":
        return "Airpods 2"
    case "2013":
        return "Airpods 3"
    case "201B":
        ///with ANC
        return "Airpods 4"
    case "2019":
        ///without ANC
        return "Airpods 4"
    case "2014":
        return "Airpods Pro 2"
    case "2003":
        return "PowerBeats 3"
    case "200d":
        return "PowerBeats 4"
    case "200b":
        return "PowerBeats Pro"
    case "200c":
        return "Beats Solo Pro"
    case "2011":
        return "Beats Studio Buds"
    case "2010":
        return "Beats Flex"
    case "2005":
        return "BeatsX"
    case "2006":
        return "Beats Solo 3"
    case "2009":
        return "Beats Studio 3"
    case "2017":
        return "Beats Studio Pro"
    case "2012":
        return "Beats Fit Pro"
    case "2016":
        return "Beats Studio Buds+"
    default:
        return "Headphones"
    }
}

func getDeviceIcon(_ d: Device) -> String {
    switch d.deviceType {
    case "blank":
        return "blank"
    case "general_bt":
        return "bluetooth.fill"
    case "MobilePhone":
        return "iphone.gen1"
    case "iPhone":
        if let model = d.deviceModel, let m = model.components(separatedBy: ",").first, let id = m.components(separatedBy: "e").last {
            if (Int(id) ?? 0 < 10) || ["iPhone12,8", "iPhone14,6"].contains(model) { return "iphone.gen1" }
            if (Int(id) ?? 0 < 14) { return "iphone.gen2" }
        }
        return "iphone"
    case "iPad":
        if let model = d.deviceModel, let m = model.components(separatedBy: ",").first, let id = m.components(separatedBy: "d").last {
            if (Int(id) ?? 0 < 13) && !["iPad8"].contains(m) { return "ipad.gen1" }
        }
        return  "ipad"
    case "iPod":
        return "ipodtouch"
    case "Watch":
        return "applewatch"
    case "RealityDevice":
        return "visionpro"
    case "Trackpad":
        return "trackpad.fill"
    case "Keyboard":
        return "keyboard.fill"
    case "MMouse":
        return "magicmouse.fill"
    case "Mouse":
        return "computermouse.fill"
    case "Gamepad":
        return "gamecontroller.fill"
    case "Headphones":
        return "headphones"
    case "Headset":
        return "headphones"
    case "ApplePencil":
        ///Model list: https://theapplewiki.com/wiki/List_of_Apple_Pencils
        if let model = d.deviceModel {
            if model == "222" { return "applepencil.gen1" }
        }
        return "applepencil.gen2"
    case "Pencil":
        return "pencil"
    case "ap_pod_right":
        if let model = d.deviceModel {
            switch model {
            case "Airpods":
                return "airpod.right"
            case "Airpods Pro":
                return "airpodpro.right"
            case "Airpods Max":
                return "airpodsmax"
            case "Airpods 2":
                return "airpod.right"
            case "Airpods 3":
                return "airpod3.right"
            case "Airpods 4":
                return "airpod4.right"
            case "Airpods Pro 2":
                return "airpodpro.right"
            case "PowerBeats 3":
                return "beats.powerbeats3.right"
            case "PowerBeats 4":
                return "beats.powerbeats4.right"
            case "PowerBeats Pro":
                return "beats.powerbeatspro.right"
            case "Beats Solo Pro":
                return "beats.headphones"
            case "Beats Studio Buds":
                return "beats.studiobud.right"
            case "Beats Flex":
                return "beats.earphones"
            case "BeatsX":
                return "beats.earphones"
            case "Beats Solo 3":
                return "beats.headphones"
            case "Beats Studio 3":
                return "beats.headphones"
            case "Beats Studio Pro":
                return "beats.headphones"
            case "Beats Fit Pro":
                return "beats.fitpro.right"
            case "Beats Studio Buds+":
                return "beats.studiobud.right"
            default:
                return "airpod.right"
            }
        }
        return "airpod.right"
    case "ap_pod_left":
        if let model = d.deviceModel {
            switch model {
            case "Airpods":
                return "airpod.left"
            case "Airpods Pro":
                return "airpodpro.left"
            case "Airpods Max":
                return "airpodsmax"
            case "Airpods 2":
                return "airpod.left"
            case "Airpods 3":
                return "airpod3.left"
            case "Airpods 4":
                return "airpod4.left"
            case "Airpods Pro 2":
                return "airpodpro.left"
            case "PowerBeats 3":
                return "beats.powerbeats3.left"
            case "PowerBeats 4":
                return "beats.powerbeats4.left"
            case "PowerBeats Pro":
                return "beats.powerbeatspro.left"
            case "Beats Solo Pro":
                return "beats.headphones"
            case "Beats Studio Buds":
                return "beats.studiobud.left"
            case "Beats Flex":
                return "beats.earphones"
            case "BeatsX":
                return "beats.earphones"
            case "Beats Solo 3":
                return "beats.headphones"
            case "Beats Studio 3":
                return "beats.headphones"
            case "Beats Studio Pro":
                return "beats.headphones"
            case "Beats Fit Pro":
                return "beats.fitpro.left"
            case "Beats Studio Buds+":
                return "beats.studiobud.left"
            default:
                return "airpod.left"
            }
        }
        return "airpod.left"
    case "ap_pod_all":
        if let model = d.deviceModel {
            switch model {
            case "Airpods":
                return "airpods"
            case "Airpods Pro":
                return "airpodspro"
            case "Airpods Max":
                return "airpodsmax"
            case "Airpods 2":
                return "airpods"
            case "Airpods 3":
                return "airpods3"
            case "Airpods 4":
                return "airpods4"
            case "Airpods Pro 2":
                return "airpodspro"
            case "PowerBeats 3":
                return "beats.powerbeats3"
            case "PowerBeats 4":
                return "beats.powerbeats4"
            case "PowerBeats Pro":
                return "beats.powerbeatspro"
            case "Beats Solo Pro":
                return "beats.headphones"
            case "Beats Studio Buds":
                return "beats.studiobud"
            case "Beats Flex":
                return "beats.earphones"
            case "BeatsX":
                return "beats.earphones"
            case "Beats Solo 3":
                return "beats.headphones"
            case "Beats Studio 3":
                return "beats.headphones"
            case "Beats Studio Pro":
                return "beats.headphones"
            case "Beats Fit Pro":
                return "beats.fitpro"
            case "Beats Studio Buds+":
                return "beats.studiobud"
            default:
                return "airpodspro"
            }
        }
        return "airpodspro"
    case "ap_case":
        if let model = d.deviceModel {
            switch model {
            case "Airpods":
                return "airpods1.case.fill"
            case "Airpods Pro":
                return "airpodspro.case.fill"
            case "Airpods Max":
                return "airpodsmax"
            case "Airpods 2":
                return "airpods.case.fill"
            case "Airpods 3":
                return "airpods3.case.fill"
            case "Airpods 4":
                return "airpods4.case.fill"
            case "Airpods Pro 2":
                return "airpodspro.case.fill"
            case "PowerBeats 3":
                return "beats.powerbeatspro.case.fill"
            case "PowerBeats 4":
                return "beats.powerbeatspro.case.fill"
            case "PowerBeats Pro":
                return "beats.powerbeatspro.case.fill"
            case "Beats Solo Pro":
                return "beats.headphones"
            case "Beats Studio Buds":
                return "beats.studiobuds.case.fill"
            case "Beats Flex":
                return "beats.earphones"
            case "BeatsX":
                return "beats.earphones"
            case "Beats Solo 3":
                return "beats.headphones"
            case "Beats Studio 3":
                return "beats.studiobuds.case.fill"
            case "Beats Studio Pro":
                return "beats.headphones"
            case "Beats Fit Pro":
                return "beats.fitpro.case.fill"
            case "Beats Studio Buds+":
                return "beats.studiobuds.case.fill"
            default:
                return "airpodspro.case.fill"
            }
        }
        return "airpodspro.case.fill"
    case "Mac":
        let m = (d.deviceModel ?? "").lowercased().replacingOccurrences(of: " ", with: "")
        if m.contains("macbook") {
            if let icon = macList[macID] { return icon }
            return "macbook"
        }
        if m.contains("macmini") { return "macmini.fill" }
        if m.contains("macstudio") { return "macstudio.fill" }
        if m.contains("macpro") { return "macpro.gen3.fill" }
        if m.contains("imac") { return "desktopcomputer" }
        return "display"
    default:
        return "questionmark.circle.fill"
    }
}

let appleMacPrefix = ["60-fd-a6", "80-a9-97", "34-8c-5e", "f0-ee-7a", "58-ad-12", "20-15-82", "40-92-1a", "10-e2-c9", "74-73-b4", "a4-fc-14", "a8-1a-f1", "cc-08-fa", "90-9b-6f", "30-82-16", "7c-29-6f", "40-ed-cf", "8c-98-6b", "1c-86-82", "80-54-e3", "b8-14-4d", "ec-28-d3", "08-65-18", "2c-57-ce", "b0-67-b5", "5c-52-84", "c0-95-6d", "3c-39-c8", "a8-ab-b5", "58-64-c4", "2c-82-17", "b0-3f-64", "14-2d-4d", "ec-42-cc", "b8-21-1c", "80-65-7c", "dc-80-84", "bc-d0-74", "c0-44-42", "d4-68-aa", "f8-c3-cc", "98-dd-60", "08-8e-dc", "a8-4a-28", "d8-be-1f", "98-50-2e", "58-0a-d4", "a4-77-f3", "84-ac-16", "2c-bc-87", "4c-ab-4f", "9c-58-3c", "c4-12-34", "3c-a6-f6", "fc-4e-a4", "f4-be-ec", "54-e6-1b", "54-09-10", "9c-fc-28", "b4-85-e1", "0c-19-f8", "50-1f-c6", "cc-69-fa", "10-ce-e9", "4c-20-b8", "14-88-e6", "b4-56-e3", "fc-66-cf", "ac-1d-06", "44-a8-fc", "f8-10-93", "e8-85-4b", "28-ec-95", "e0-2b-96", "f4-db-e3", "b4-40-a4", "48-b8-a3", "10-29-59", "e4-76-84", "f0-5c-d5", "70-ea-5a", "b8-7b-c5", "40-70-f5", "b0-35-b5", "80-0c-67", "90-81-2a", "60-8b-0e", "88-b2-91", "c4-2a-d0", "cc-d2-81", "10-40-f3", "44-e6-6e", "c0-e8-62", "f4-06-16", "58-6b-14", "bc-b8-63", "40-26-19", "6c-e8-5c", "e4-b2-fb", "f8-38-80", "4c-56-9d", "38-53-9c", "10-94-bb", "f8-6f-c1", "28-ff-3c", "f0-99-b6", "88-e9-fe", "38-89-2c", "74-9e-af", "94-bf-2d", "40-cb-c0", "c4-61-8b", "08-e6-89", "dc-56-e7", "24-f6-77", "b0-ca-68", "c8-3c-85", "54-33-cb", "34-08-bc", "1c-36-bb", "3c-2e-ff", "00-db-70", "b8-63-4d", "a4-e9-75", "30-35-ad", "84-41-67", "98-00-c6", "ac-1f-74", "a8-5c-2c", "70-f0-87", "24-5b-a7", "b0-70-2d", "6c-19-c0", "2c-33-61", "24-f0-94", "08-6d-41", "ec-ad-b8", "98-01-a7", "e0-c7-67", "80-ed-2c", "ac-61-ea", "38-b5-4d", "1c-5c-f2", "28-ed-6a", "a4-d1-8c", "24-1e-eb", "cc-25-ef", "28-cf-e9", "00-a0-40", "cc-08-e0", "f0-b4-79", "10-93-e9", "44-2a-60", "00-21-e9", "00-26-08", "00-26-b0", "00-26-bb", "c8-2a-14", "3c-07-54", "a4-b1-97", "00-30-65", "00-14-51", "00-1e-52", "d4-9a-20", "f8-1e-df", "a4-d1-d2", "28-cf-da", "04-54-53", "3c-d0-f8", "68-09-27", "6c-c2-6b", "94-94-26", "20-7d-74", "f4-f1-5a", "c8-6f-1d", "30-90-ab", "8c-2d-aa", "84-85-06", "98-fe-94", "d8-00-4d", "54-26-96", "64-a3-cb", "30-f7-c5", "40-b3-95", "44-fb-42", "e8-8d-28", "c8-b5-b7", "90-b2-1f", "b8-e8-56", "d8-96-95", "44-d8-84", "64-20-0c", "c8-33-4b", "64-e6-82", "f4-f9-51", "c0-63-94", "18-af-8f", "14-99-e2", "b4-18-d1", "9c-20-7b", "b0-65-bd", "a0-99-9b", "24-24-0e", "90-3c-92", "d8-1d-72", "34-12-98", "70-e7-2c", "70-ec-e4", "d8-bb-2c", "d0-4f-7e", "9c-f3-87", "a8-5b-78", "f0-db-f8", "48-74-6e", "54-ae-27", "c8-f6-50", "fc-e9-98", "0c-bc-9f", "34-36-3b", "d0-a6-37", "78-9f-70", "20-78-f0", "e0-ac-cb", "68-ae-20", "ac-87-a3", "a8-8e-24", "cc-20-e8", "70-48-0f", "f0-b0-e7", "04-69-f8", "50-a6-d8", "68-ca-c4", "a0-d1-b3", "7c-4b-26", "cc-11-5a", "0c-6a-c4", "bc-37-d3", "0c-51-7e", "40-da-5c", "5c-91-75", "a0-78-2d", "d0-11-e5", "dc-71-d0", "9c-fa-76", "20-fa-85", "9c-1a-25", "1c-0e-c2", "04-41-a5", "1c-f6-4c", "ac-5c-2c", "50-f2-65", "c0-6c-0c", "9c-da-a8", "cc-4b-04", "44-09-da", "80-96-98", "c4-84-fc", "0c-c5-6c", "d4-0f-9e", "98-0d-af", "dc-6d-bc", "a4-d2-3e", "30-e0-4f", "60-82-46", "98-b3-79", "04-9d-05", "3c-1e-b5", "ac-86-a3", "14-1a-97", "b8-3c-28", "3c-6d-89", "ac-45-00", "84-b1-e4", "54-eb-e9", "ac-16-15", "ec-73-79", "c4-35-d9", "ac-c9-06", "04-bc-6d", "d0-da-d7", "c4-ac-aa", "2c-32-6a", "6c-b1-33", "70-b3-06", "b8-49-6d", "9c-92-4f", "20-0e-2b", "f0-d7-93", "74-71-8b", "70-31-7f", "a4-cf-99", "4c-2e-b4", "b4-19-74", "60-95-bd", "b0-de-28", "34-28-40", "18-e7-b0", "50-57-8a", "d4-fb-8e", "44-1b-88", "80-04-5f", "9c-3e-53", "c8-89-f3", "10-b9-c4", "a0-a3-09", "5c-50-d9", "88-4d-7c", "a8-fe-9d", "b0-be-83", "dc-f4-ca", "7c-fc-16", "88-b9-45", "24-5e-48", "08-c7-29", "c4-c3-6b", "e8-a7-30", "60-06-e3", "b8-81-fa", "9c-76-0e", "94-ea-32", "50-f4-eb", "28-c7-09", "14-d1-9e", "40-c7-11", "5c-70-17", "8c-ec-7b", "9c-28-b3", "a0-78-17", "5c-87-30", "b4-1b-b0", "58-d3-49", "f4-34-f0", "b0-8c-75", "74-8f-3c", "40-f9-46", "64-0b-d7", "a8-91-3d", "0c-3b-50", "20-e8-74", "d0-3f-aa", "7c-ab-60", "44-c6-5d", "18-7e-b9", "08-f8-bc", "90-a2-5b", "88-a4-79", "04-72-95", "d4-46-e1", "3c-bf-60", "ac-15-f4", "78-d1-62", "14-87-6a", "e0-b5-5f", "f8-ff-c2", "e0-eb-40", "c8-b1-cd", "14-60-cb", "b8-f1-2a", "f8-87-f1", "30-57-14", "80-4a-14", "70-3c-69", "14-c2-13", "a4-d9-31", "bc-fe-d9", "80-82-23", "bc-e1-43", "30-d9-d9", "60-30-d4", "f8-95-ea", "18-f1-d8", "64-70-33", "84-68-78", "c8-d0-83", "70-ef-00", "d0-81-7a", "98-ca-33", "68-ab-1e", "0c-15-39", "d8-8f-76", "40-9c-28", "58-e2-8f", "78-7b-8a", "50-32-37", "b0-48-1a", "b4-9c-df", "48-bf-6b", "9c-84-bf", "00-b3-62", "e4-e4-ab", "60-33-4b", "fc-d8-48", "a8-60-b6", "c4-b3-01", "e0-5f-45", "48-3b-38", "1c-91-48", "30-63-6b", "a4-f1-e8", "44-00-10", "00-56-cd", "00-cd-fe", "e4-98-d6", "f4-31-c3", "64-a5-c3", "00-10-fa", "00-50-e4", "00-0d-93", "00-19-e3", "00-1b-63", "00-1e-c2", "00-1f-f3", "00-23-32", "00-23-6c", "00-23-df", "00-25-00", "00-25-bc", "34-15-9e", "58-b0-35", "5c-59-48", "c8-bc-c8", "7c-fa-df", "24-ab-81", "78-a3-e4", "1c-ab-a7", "e0-f8-47", "28-e7-cf", "e4-ce-8f", "e8-04-0b", "14-5a-05", "14-8f-c6", "28-6a-b8", "28-e0-2c", "e0-b9-ba", "00-c6-10", "7c-d1-c3", "f0-dc-e2", "a8-20-66", "bc-52-b7", "c0-84-7a", "b8-f6-b1", "8c-fa-ba", "88-1f-a1", "c8-e0-eb", "98-b8-e3", "88-53-95", "78-6c-1c", "4c-8d-79", "1c-e6-2b", "24-a2-e1", "80-ea-96", "60-03-08", "04-f1-3e", "98-f0-ab", "08-74-02", "94-f6-a3", "98-e0-d9", "cc-29-f5", "28-5a-eb", "74-81-14", "18-f6-43", "a4-5e-60", "a0-18-28", "d0-03-4b", "24-a0-74", "f0-24-75", "2c-1f-23", "54-9f-13", "f0-db-e2", "0c-30-21", "dc-86-d8", "90-b9-31", "d0-e1-40", "10-41-7f", "a8-66-7f", "d0-25-98", "78-3a-84", "5c-8d-4e", "88-63-df", "84-78-8b", "80-be-05", "78-31-c1", "0c-3e-9f", "fc-fc-48", "9c-29-3f", "58-7f-57", "00-6d-52", "b8-44-d9", "90-2c-09", "a0-b4-0f", "ec-0d-51", "ac-df-a1", "d8-e5-93", "cc-68-e0", "f4-fe-3e", "34-2b-6e", "60-65-25", "f4-39-a6", "fc-55-57", "9c-58-84", "24-b3-39", "14-35-b7", "64-48-42", "f4-52-93", "94-21-57", "88-6b-db", "04-13-7a", "70-f9-4a", "90-b7-90", "f0-d6-35", "74-42-18", "90-4c-c5", "ec-46-54", "50-f3-51", "20-2d-f6", "20-91-df", "a8-9c-78", "7c-61-30", "80-b9-89", "c4-52-4f", "60-3e-5f", "84-88-e1", "10-bd-3a", "18-4a-53", "10-9f-41", "70-72-fe", "2c-c2-53", "28-02-2e", "fc-9c-a7", "48-e1-5c", "74-15-f5", "2c-18-09", "fc-47-d8", "70-ae-d5", "94-ad-23", "20-a5-cb", "f4-21-ca", "bc-89-a7", "68-83-cb", "5c-e9-1e", "7c-ec-b1", "20-78-cd", "30-d5-3e", "50-23-a2", "98-69-8a", "78-fb-d8", "a4-c3-37", "b0-f1-d8", "d0-88-0c", "1c-57-dc", "48-35-2b", "4c-e6-c0", "38-88-a4", "44-da-30", "28-ea-2d", "b8-e6-0c", "28-c5-38", "04-99-b9", "78-02-8b", "f8-4d-89", "00-8a-76", "20-37-a5", "dc-b5-4f", "b8-37-4a", "94-5c-9a", "00-f3-9f", "e0-92-5c", "1c-91-80", "4c-b9-10", "34-31-8f", "c4-14-11", "cc-c9-5d", "f8-66-5a", "60-be-c4", "f8-b1-dd", "a8-81-7e", "78-e3-de", "d0-d2-3c", "64-d2-c4", "dc-52-85", "e8-81-52", "90-81-58", "60-7e-c9", "14-c8-8b", "ec-26-51", "18-3e-ef", "3c-7d-0a", "b8-90-47", "90-9c-4a", "90-8c-43", "ec-ce-d7", "ac-90-85", "88-a9-b7", "28-77-f1", "f0-a3-5a", "60-83-73", "84-ad-8d", "74-42-8b", "54-2b-8d", "50-7a-c5", "4c-6b-e8", "8c-86-1e", "44-18-fd", "00-5b-94", "e0-89-7e", "38-f9-d3", "fc-18-3c", "64-c7-53", "58-e6-ba", "90-e1-7b", "d8-1c-79", "08-f6-9c", "50-a6-7f", "14-20-5e", "b8-41-a4", "9c-e6-5e", "c4-98-80", "e0-33-8e", "d4-61-da", "f0-18-98", "88-19-08", "5c-09-47", "d4-90-9c", "e4-e0-a6", "80-b0-3d", "e4-9a-dc", "ac-e4-b5", "d0-d2-b0", "8c-85-90", "6c-96-cf", "78-88-6d", "20-ee-28", "b4-f6-1c", "08-f4-ab", "6c-ab-31", "4c-74-bf", "98-9e-63", "88-6b-6e", "d4-dc-cd", "48-4b-aa", "dc-a9-04", "50-82-d5", "64-b0-a6", "7c-04-d0", "84-fc-ac", "dc-0c-5c", "70-70-0d", "18-65-90", "f8-62-14", "78-4f-43", "40-4d-7f", "60-9a-c1", "74-8d-08", "9c-8b-a0", "cc-08-8d", "10-dd-b1", "c0-1a-da", "0c-51-01", "2c-f0-a2", "68-fb-7e", "84-a1-34", "e8-b2-ac", "e4-9a-79", "b4-4b-d2", "dc-41-5f", "20-76-8f", "f4-5c-89", "38-ca-da", "18-af-61", "5c-f9-38", "34-ab-37", "cc-44-63", "6c-72-e7", "74-1b-b2", "60-fe-c5", "e4-25-e7", "bc-92-6b", "10-1c-0c", "08-00-07", "00-16-cb", "00-17-f2", "00-1f-5b", "00-24-36", "00-25-4b", "a8-fa-d8", "00-88-65", "bc-3b-af", "3c-e0-72", "38-48-4c", "80-49-71", "6c-3e-6d", "bc-67-78", "20-c9-d0", "68-96-7b", "7c-6d-62", "40-d3-2d", "c4-2c-03", "90-27-e4", "84-fc-fe", "e4-8b-7f", "d8-d1-cb", "b8-17-c2", "7c-11-be", "98-d6-bb", "a4-67-06", "8c-58-77", "7c-f0-5f", "10-9a-dd", "58-1f-aa", "88-c6-63", "28-37-37", "50-ea-d6", "18-9e-fc", "ac-cf-5c", "80-00-6e", "84-8e-0c", "3c-15-c2", "6c-70-9f", "64-76-ba", "34-e2-fd", "04-48-9a", "90-fd-61", "2c-f0-ee", "5c-97-f3", "d4-f4-6f", "5c-f5-da", "18-ee-69", "64-9a-be", "f0-99-bf", "48-43-7c", "34-a3-95", "78-7e-61", "60-f8-1d", "c0-f2-fb", "24-e3-14", "80-e6-50", "a4-c3-61", "b0-9f-ba", "0c-4d-e9", "e0-f5-c6", "a0-ed-cd", "f0-f6-1c", "8c-29-37", "08-70-45", "a8-88-08", "d0-33-11", "94-e9-6a", "ac-29-3a", "9c-fc-01", "9c-35-eb", "50-7a-55", "38-c9-86", "20-9b-cd", "dc-10-57", "30-d8-75", "68-3e-c0", "80-95-3a", "68-45-cc", "ac-97-38", "cc-60-23", "0c-db-ea", "8c-26-aa", "90-62-3f", "a8-bb-56", "28-2d-7f", "b0-d5-76", "14-28-76", "14-7f-ce", "38-e1-3d", "d0-d4-9f", "9c-60-76", "90-5f-7a", "f8-f5-8c", "0c-85-e1", "c4-b3-49", "34-f6-8d", "cc-27-46", "f8-e5-ce", "28-c1-a0", "ec-2c-73", "7c-c0-6f", "ec-81-50", "d4-2f-ca", "d0-58-a5", "94-3f-d6", "10-cf-0f", "fc-31-5d", "74-a6-cd", "2c-7c-f2", "30-d7-a1", "20-1a-94", "b0-e5-ef", "28-8f-f6", "58-b9-65", "74-31-74", "f0-c7-25", "6c-7e-67", "a4-c6-f0", "a8-8f-d9", "08-95-42", "e4-9c-67", "1c-6a-76", "5c-3e-1b", "7c-2a-ca", "28-8e-ec", "04-99-bb", "5c-1b-f4", "a8-51-ab", "7c-c1-80", "28-02-44", "e8-5f-02", "60-dd-70", "98-a5-f9", "ec-a9-07", "c0-2c-5c", "d4-57-63", "10-00-20", "8c-7a-aa", "7c-24-99", "e8-78-65", "a0-4e-cf", "08-87-c7", "38-65-b2", "d8-de-3a", "84-8c-8d", "0c-e4-41", "b8-2a-a9", "78-64-c0", "e8-1c-d8", "3c-06-30", "f4-d4-88", "68-2f-67", "50-ed-3c", "44-f2-1b", "74-65-0c", "e0-6d-17", "f0-b3-ec", "f4-65-a6", "98-60-ca", "44-90-bb", "34-fd-6a", "44-35-83", "80-5f-c5", "3c-4d-be", "48-26-2c", "14-7d-da", "c4-91-0c", "20-69-80", "d8-dc-40", "e4-90-fd", "84-ab-1a", "d0-65-44", "38-ec-0d", "94-0c-98", "e8-fb-e9", "7c-a1-ae", "3c-22-fb", "60-70-c0", "f0-c3-71", "18-55-e3", "e4-50-eb", "88-64-40", "94-16-25", "34-a8-eb", "a4-83-e7", "f4-af-e7", "ac-88-fd", "dc-08-0f", "f8-e9-4e", "ec-2c-e2", "40-bc-60", "e8-36-17", "9c-64-8b", "34-42-62", "14-d0-0d", "90-dd-5d", "64-5a-ed", "fc-2a-9c", "a0-56-f3", "54-99-63", "c0-b6-58", "48-a9-1c", "50-bc-96", "c4-84-66", "34-7c-25", "cc-2d-b7", "a0-4e-a7", "f0-98-9d", "e4-2b-34", "3c-2e-f9", "b0-19-c6", "38-66-f0", "70-3e-ac", "98-10-e8", "c0-d0-12", "bc-a9-20", "48-a1-95", "f8-03-77", "dc-a4-ca", "8c-8f-e9", "2c-20-0b", "88-66-a5", "00-1c-b3", "f0-79-60", "a0-d7-95", "b8-ff-61", "70-a2-b3", "f4-0f-24", "4c-57-ca", "90-c1-c6", "48-e9-f1", "1c-9e-46", "9c-4f-da", "c0-cc-f8", "84-89-ad", "0c-d7-46", "60-a3-7d", "68-db-ca", "08-66-98", "bc-54-36", "04-4b-ed", "6c-8d-c1", "90-60-f1", "b8-78-2e", "00-05-02", "98-03-d8", "d8-9e-3f", "b8-c7-5d", "0c-74-c2", "90-84-0d", "e8-06-88", "7c-c5-37", "78-ca-39", "18-e7-f4", "70-cd-60", "8c-7b-9d", "00-22-41", "00-26-4a", "04-1e-64", "00-0a-95", "00-11-24", "cc-78-5f", "88-cb-87", "68-5b-35", "2c-b4-3a", "68-9c-70", "38-0f-4a", "44-4c-0c", "b4-f0-ab", "80-92-9f", "9c-04-eb", "5c-96-9d", "30-10-e4", "a8-86-dd", "f0-c1-f1", "84-38-35", "8c-00-6d", "5c-95-ae", "84-29-99", "74-e2-f5", "e0-c9-7a", "a8-96-8a", "f4-1b-a1", "04-15-52", "68-a8-6d", "7c-c3-a1", "70-73-cb", "90-72-40", "f8-27-93", "40-30-04", "60-c5-47", "ec-85-2f", "00-f4-b9", "3c-ab-8e", "60-92-17", "84-b1-53", "e0-66-78", "48-d7-05", "68-d9-3c", "00-f7-6f", "c8-85-50", "e0-b5-2d", "a4-31-35", "70-14-a6", "98-5a-eb", "78-d7-5f", "4c-7c-5f", "68-64-4b", "c8-1e-e7", "6c-94-f8", "90-8d-6c", "b8-09-8a", "c0-ce-cd", "60-d9-c7", "a4-b8-05", "5c-ad-cf", "bc-6c-21", "c8-69-cd", "ac-bc-32", "54-4e-90", "a4-f8-41", "a0-52-72", "34-b1-eb", "20-04-84", "f8-71-a6", "78-a7-c7", "98-fe-e1", "d0-c0-50", "84-94-37", "2c-81-bf", "28-34-ff", "d0-3e-07", "50-b1-27", "bc-bb-58", "30-3b-7c", "00-81-2a", "1c-e2-09", "40-d1-60", "d0-e5-81", "94-0b-cd", "1c-3c-78", "60-f5-49", "10-da-63", "8c-08-aa", "f4-a3-10", "3c-3b-77", "e8-4a-78", "6c-1f-8a", "6c-3a-ff", "ec-97-a2", "44-9e-8b", "e0-c3-ea", "38-9c-b2", "58-36-53", "84-d3-28", "c0-17-54", "a4-16-c0", "dc-45-b8", "90-ec-ea", "10-b5-88", "f0-d3-1f", "b4-ae-c1", "54-32-c7", "60-d0-39", "c4-c1-7d", "e0-bd-a0", "58-73-d8", "f4-e8-c7", "14-85-09", "18-fa-b7", "70-22-fe", "88-1e-5a", "00-c5-85", "a8-7c-f8", "2c-76-00", "f8-7d-76", "ac-bc-b5", "08-25-73", "ac-00-7a", "f0-1f-c7", "88-20-0d", "1c-0d-7d", "14-f2-87", "58-55-95", "14-94-6c", "a8-5b-b7", "6c-e5-c9", "fc-e2-6c", "4c-79-75", "1c-71-25", "34-fe-77", "04-68-65", "dc-53-92", "1c-b3-c9", "fc-aa-81", "60-93-16", "64-6d-2f", "64-5a-36", "20-32-c6", "5c-52-30", "ac-49-db", "44-f0-9e", "08-ff-44", "18-56-c3", "b8-8d-12", "f0-2f-4b", "40-e6-4b", "b4-fa-48", "14-98-77", "88-66-5a", "b0-e5-f9", "c4-0b-31", "bc-a5-a9", "20-e2-a8", "a0-fb-c5", "00-7d-60", "7c-6d-f8", "e8-7f-95", "88-c0-8b", "4c-7c-d9", "bc-09-63", "d8-4c-90", "24-d0-df", "6c-4a-85", "28-f0-33", "44-4a-db", "30-90-48", "f8-4e-73", "3c-cd-36", "f0-78-07", "08-2c-b6", "74-e1-b6", "f4-0e-01", "14-95-ce", "50-de-06", "cc-66-0a", "fc-1d-43", "54-62-e2", "14-9d-99", "b8-b2-f8", "98-46-0a", "b8-5d-0a", "7c-9a-1d", "10-30-25", "c0-9a-d0", "94-b0-1f", "94-f6-d6", "f8-2d-7c", "18-81-0e", "60-8c-4a", "24-1b-7a", "8c-fe-57", "c0-a6-00", "74-b5-87", "fc-b6-d8", "00-03-93", "1c-1a-c0", "88-ae-07", "40-83-1d", "dc-d3-a2", "5c-1d-d9", "68-fe-f7", "d4-a3-3d", "f0-76-6f", "40-98-ad", "6c-4d-73", "68-ef-43", "d0-2b-20", "2c-61-f6", "9c-e3-3f", "78-67-d7", "b8-c1-11", "a8-be-27", "c0-a5-3e", "14-bd-61", "d4-61-9d", "7c-50-49", "58-40-4e", "d0-c5-f3", "bc-9f-ef", "20-ab-37", "60-f4-45", "88-e8-7f", "9c-f4-8e", "5c-f7-e6", "b8-53-ac", "20-3c-ae", "a0-3b-e3", "4c-32-75", "d8-30-62", "8c-8e-f2", "90-b0-ed", "04-d3-cf", "b4-8b-19", "bc-ec-5d", "28-a0-2b", "60-69-44", "38-71-de", "70-81-eb", "04-52-f3", "70-de-e2", "f0-cb-a1", "18-20-32", "60-fa-cd", "00-3e-e1", "40-3c-fc", "48-60-bc", "34-51-c9", "40-6c-8f", "d0-23-db", "58-55-ca", "dc-2b-61", "40-a6-d9", "64-b9-e8", "d8-a2-5e", "00-23-12", "60-fb-42", "00-0a-27", "00-1d-4f", "04-0c-ce", "fc-25-3f", "18-34-51", "0c-77-1a", "28-6a-ba", "4c-b1-99", "c0-9f-42", "54-ea-a8", "28-e1-4c", "e4-c6-3d", "54-e4-3a", "04-db-56", "04-e5-36", "ac-3c-0b", "70-11-24", "04-26-65", "ec-35-86", "dc-9b-9c", "54-72-4f", "8c-7c-92", "b0-34-95", "a8-bb-cf", "ac-7f-3e", "28-0b-5c", "ac-fd-ec", "34-c0-59", "f0-d1-a9", "14-10-9f", "04-f7-e4", "f4-37-b7", "70-56-81", "d8-cf-9c", "78-fd-94", "2c-be-08", "e8-80-2e", "00-61-71", "dc-37-14", "40-33-1a", "cc-c7-60", "28-f0-76", "bc-4c-c4", "6c-40-08", "20-a2-e4", "7c-01-91", "80-d6-05", "dc-2b-2a", "28-83-c9", "18-3f-70", "a4-f6-e8", "64-41-e6", "70-bb-5b", "74-0e-a4", "60-57-c8", "d0-6b-78", "0c-53-b7", "7c-f3-4d", "f8-42-88", "60-0f-6b", "4c-97-cc", "88-b7-eb", "10-a2-d3", "34-ee-16", "ac-07-75", "84-2f-57", "64-0c-91", "58-93-e8", "f0-04-e1", "70-8c-f2", "f8-73-df", "14-1b-a0", "cc-81-7d", "2c-ca-16", "14-14-7d", "cc-3f-36", "10-2f-ca"]

let macList = ["MacBookPro1,1": "macbook.gen1", "MacBookPro1,2": "macbook.gen1", "MacBookPro2,1": "macbook.gen1", "MacBookPro2,2": "macbook.gen1", "MacBookPro3,1": "macbook.gen1", "MacBookPro4,1": "macbook.gen1", "MacBookPro5,1": "macbook.gen1", "MacBookPro5,2": "macbook.gen1", "MacBookPro5,3": "macbook.gen1", "MacBookPro5,4": "macbook.gen1", "MacBookPro5,5": "macbook.gen1", "MacBookPro6,1": "macbook.gen1", "MacBookPro6,2": "macbook.gen1", "MacBookPro7,1": "macbook.gen1", "MacBookPro8,1": "macbook.gen1", "MacBookPro8,2": "macbook.gen1", "MacBookPro8,3": "macbook.gen1", "MacBookPro9,1": "macbook.gen1", "MacBookPro9,2": "macbook.gen1", "MacBookPro10,1": "macbook.gen1", "MacBookPro10,2": "macbook.gen1", "MacBookPro11,1": "macbook.gen1", "MacBookPro11,2": "macbook.gen1", "MacBookPro11,3": "macbook.gen1", "MacBookPro11,4": "macbook.gen1", "MacBookPro11,5": "macbook.gen1", "MacBookPro12,1": "macbook.gen1", "MacBookPro13,1": "macbook.gen1", "MacBookPro13,2": "macbook.gen1", "MacBookPro13,3": "macbook.gen1", "MacBookPro14,1": "macbook.gen1", "MacBookPro14,2": "macbook.gen1", "MacBookPro14,3": "macbook.gen1", "MacBookPro15,1": "macbook.gen1", "MacBookPro15,2": "macbook.gen1", "MacBookPro15,3": "macbook.gen1", "MacBookPro15,4": "macbook.gen1", "MacBookPro16,1": "macbook.gen1", "MacBookPro16,2": "macbook.gen1", "MacBookPro16,3": "macbook.gen1", "MacBookPro16,4": "macbook.gen1", "MacBookPro17,1": "macbook.gen1", "MacBookPro18,1": "macbook", "MacBookPro18,2": "macbook", "MacBookPro18,3": "macbook", "MacBookPro18,4": "macbook", "Mac14,5": "macbook", "Mac14,6": "macbook", "Mac14,7": "macbook.gen1", "Mac14,9": "macbook", "Mac14,10": "macbook", "Mac15,3": "macbook", "Mac15,6": "macbook", "Mac15,7": "macbook", "Mac15,8": "macbook", "Mac15,9": "macbook", "Mac15,10": "macbook", "Mac15,11": "macbook", "MacBookAir1,1": "macbook.gen1", "MacBookAir2,1": "macbook.gen1", "MacBookAir3,1": "macbook.gen1", "MacBookAir3,2": "macbook.gen1", "MacBookAir4,1": "macbook.gen1", "MacBookAir4,2": "macbook.gen1", "MacBookAir5,1": "macbook.gen1", "MacBookAir5,2": "macbook.gen1", "MacBookAir6,1": "macbook.gen1", "MacBookAir6,2": "macbook.gen1", "MacBookAir7,1": "macbook.gen1", "MacBookAir7,2": "macbook.gen1", "MacBookAir8,1": "macbook.gen1", "MacBookAir8,2": "macbook.gen1", "MacBookAir9,1": "macbook.gen1", "MacBookAir10,1": "macbook.gen1", "Mac14,2": "macbook", "Mac14,15": "macbook", "Mac15,12": "macbook", "Mac15,13": "macbook", "MacBook1,1": "macbook.gen1", "MacBook2,1": "macbook.gen1", "MacBook3,1": "macbook.gen1", "MacBook4,1": "macbook.gen1", "MacBook5,1": "macbook.gen1", "MacBook5,2": "macbook.gen1", "MacBook6,1": "macbook.gen1", "MacBook7,1": "macbook.gen1", "MacBook8,1": "macbook.gen1", "MacBook9,1": "macbook.gen1", "MacBook10,1": "macbook.gen1"]
