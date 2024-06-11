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

let dockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
let alertTimer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()
let widgetDataTimer = Timer.publish(every: 25, on: .main, in: .common).autoconnect()
let widgetInterval = UserDefaults.standard.integer(forKey: "widgetInterval")
let updateInterval = UserDefaults.standard.double(forKey: "updateInterval")
let nearCastTimer = Timer.publish(every: TimeInterval(60 * updateInterval + Double(arc4random_uniform(10)) - Double(arc4random_uniform(10))), on: .main, in: .common).autoconnect()
let widgetViewTimer = Timer.publish(every: TimeInterval(60 * (widgetInterval != 0 ? Double(abs(widgetInterval)) : updateInterval)), on: .main, in: .common).autoconnect()
let macList = ["MacBookPro1,1":"macbook.gen1", "MacBookPro1,2":"macbook.gen1", "MacBookPro2,1":"macbook.gen1", "MacBookPro2,2":"macbook.gen1", "MacBookPro3,1":"macbook.gen1", "MacBookPro4,1":"macbook.gen1", "MacBookPro5,1":"macbook.gen1", "MacBookPro5,2":"macbook.gen1", "MacBookPro5,3":"macbook.gen1", "MacBookPro5,4":"macbook.gen1", "MacBookPro5,5":"macbook.gen1", "MacBookPro6,1":"macbook.gen1", "MacBookPro6,2":"macbook.gen1", "MacBookPro7,1":"macbook.gen1", "MacBookPro8,1":"macbook.gen1", "MacBookPro8,2":"macbook.gen1", "MacBookPro8,3":"macbook.gen1", "MacBookPro9,1":"macbook.gen1", "MacBookPro9,2":"macbook.gen1", "MacBookPro10,1":"macbook.gen1", "MacBookPro10,2":"macbook.gen1", "MacBookPro11,1":"macbook.gen1", "MacBookPro11,2":"macbook.gen1", "MacBookPro11,3":"macbook.gen1", "MacBookPro11,4":"macbook.gen1", "MacBookPro11,5":"macbook.gen1", "MacBookPro12,1":"macbook.gen1", "MacBookPro13,1":"macbook.gen1", "MacBookPro13,2":"macbook.gen1", "MacBookPro13,3":"macbook.gen1", "MacBookPro14,1":"macbook.gen1", "MacBookPro14,2":"macbook.gen1", "MacBookPro14,3":"macbook.gen1", "MacBookPro15,1":"macbook.gen1", "MacBookPro15,2":"macbook.gen1", "MacBookPro15,3":"macbook.gen1", "MacBookPro15,4":"macbook.gen1", "MacBookPro16,1":"macbook.gen1", "MacBookPro16,2":"macbook.gen1", "MacBookPro16,3":"macbook.gen1", "MacBookPro16,4":"macbook.gen1", "MacBookPro17,1":"macbook.gen1", "MacBookPro18,1":"macbook", "MacBookPro18,2":"macbook", "MacBookPro18,3":"macbook", "MacBookPro18,4":"macbook", "Mac14,5":"macbook", "Mac14,6":"macbook", "Mac14,7":"macbook.gen1", "Mac14,9":"macbook", "Mac14,10":"macbook", "Mac15,3":"macbook", "Mac15,6":"macbook", "Mac15,7":"macbook", "Mac15,8":"macbook", "Mac15,9":"macbook", "Mac15,10":"macbook", "Mac15,11":"macbook"]
let macID = getMacModelIdentifier()

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

public func process(path: String, arguments: [String]) -> String? {
    let task = Process()
    task.launchPath = path
    task.arguments = arguments
    task.standardError = Pipe()
    
    let outputPipe = Pipe()
    defer {
        outputPipe.fileHandleForReading.closeFile()
    }
    task.standardOutput = outputPipe
    
    do {
        try task.run()
    } catch let error {
        print("\(error.localizedDescription)")
        return nil
    }
    
    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(decoding: outputData, as: UTF8.self)
    
    if output.isEmpty {
        return nil
    }
    
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
            return iBattery(hasBattery: true, isCharging: internalBattery.isCharging ?? false, isCharged :internalBattery.isCharged ?? false, acPowered: internalBattery.acPowered ?? false, timeLeft: internalBattery.timeLeft, batteryLevel: Int(level))
        }
    }
    return iBattery(hasBattery: false, isCharging: false, isCharged: false, acPowered: false, timeLeft: "", batteryLevel: 0)
}

func getPowerColor(_ level: Int, emoji: Bool = false) -> String {
    var colorName = "my_green"
    var colorEmoji = "🟩"
    if level <= 10 {
        colorName = "my_red"
        colorEmoji = "🟥"
    } else if level <= 20 {
        colorName = "my_yellow"
        colorEmoji = "🟨"
    }
    if emoji { return colorEmoji }
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
    return Device(hasBattery: ib.hasBattery, deviceID: "@MacInternalBattery", deviceType: "Mac", deviceName: deviceName, deviceModel: machineType, batteryLevel: ib.batteryLevel, isCharging: ib.isCharging ? 1 : 0, isCharged: ib.isCharged, acPowered: ib.acPowered, lastUpdate: Double(Date().timeIntervalSince1970))
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
    for device in AirBatteryModel.getAll().filter({ $0.batteryLevel <= alertLevel && $0.isCharging == 0 && alertList.contains($0.deviceName) }) {
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
    for device in AirBatteryModel.getAll().filter({ $0.batteryLevel >= fullyLevel && $0.isCharging != 0 && alertList.contains($0.deviceName) }) {
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
            if (Int(id) ?? 0 > 9) && !["iPhone12,8", "iPhone14,6"].contains(model) { return "iphone" }
            return "iphone.gen1" }
        return "iphone"
    case "iPad":
        if let model = d.deviceModel, let m = model.components(separatedBy: ",").first {
            if ["iPad8", "iPad13", "iPad14"].contains(m) { return "ipad" }
            return "ipad.gen1" }
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
    case "Headphones":
        return "headphones"
    case "Headset":
        return "headphones"
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
                return "airpod3.right"
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
