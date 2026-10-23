import Cocoa
import CoreMotion
import Network

final class App: NSObject, NSApplicationDelegate {
    let motion = CMHeadphoneMotionManager()
    let connection = NWConnection(host: "127.0.0.1", port: 9010, using: .udp)
    var window: NSWindow!
    let label = NSTextField(wrappingLabelWithString: "Connect compatible AirPods, then click Start.\nOSC → localhost:9010")
    var lastUI = 0.0
    func applicationDidFinishLaunching(_ notification: Notification) {
        connection.start(queue: .main)
        window = NSWindow(contentRect: NSRect(x: 0,y: 0,width: 520,height: 240), styleMask: [.titled,.closable,.miniaturizable], backing: .buffered, defer: false)
        window.title = "AirPods Motion — CHOP Bridge"
        label.frame = NSRect(x: 24,y: 90,width: 472,height: 125)
        window.contentView!.addSubview(label)
        let start = NSButton(title: "Start sensor", target: self, action: #selector(startMotion))
        start.frame = NSRect(x: 24,y: 30,width: 150,height: 36)
        window.contentView!.addSubview(start)
        let stop = NSButton(title: "Stop", target: self, action: #selector(stopMotion))
        stop.frame = NSRect(x: 190,y: 30,width: 100,height: 36)
        window.contentView!.addSubview(stop)
        window.center(); window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    func osc(_ address: String, _ value: Float) {
        func padded(_ s: String) -> Data { var d = Data(s.utf8); d.append(0); while d.count % 4 != 0 { d.append(0) }; return d }
        var data = padded(address); data.append(padded(",f"))
        var bits = value.bitPattern.bigEndian
        withUnsafeBytes(of: &bits) { data.append(contentsOf: $0) }
        connection.send(content: data, completion: .contentProcessed { _ in })
    }
    @objc func startMotion() {
        motion.stopDeviceMotionUpdates()
        guard motion.isDeviceMotionAvailable else { label.stringValue = "Motion unavailable. Connect compatible AirPods and retry.\nCheck macOS Motion permissions if needed."; return }
        label.stringValue = "Waiting for sensor samples…\nIf no data arrives, first test while wearing the AirPods."
        motion.startDeviceMotionUpdates(to: .main) { [weak self] sample, error in
            guard let self = self else { return }
            if let error = error { self.label.stringValue = error.localizedDescription; return }
            guard let m = sample else { return }
            let a = m.userAcceleration; let g = m.gravity
            let vertical = -(a.x*g.x + a.y*g.y + a.z*g.z)
            let fields: [(String, Double)] = [("ax",a.x),("ay",a.y),("az",a.z),("vertical",vertical),("pitch",m.attitude.pitch),("roll",m.attitude.roll),("yaw",m.attitude.yaw),("gx",g.x),("gy",g.y),("gz",g.z),("rx",m.rotationRate.x),("ry",m.rotationRate.y),("rz",m.rotationRate.z),("qx",m.attitude.quaternion.x),("qy",m.attitude.quaternion.y),("qz",m.attitude.quaternion.z),("qw",m.attitude.quaternion.w),("source",Double(m.sensorLocation.rawValue)),("tick",m.timestamp.truncatingRemainder(dividingBy: 10000))]
            for (key,value) in fields { self.osc("/" + key, Float(value)) }
            if m.timestamp - self.lastUI > 0.2 {
                self.lastUI = m.timestamp
                self.label.stringValue = String(format: "Streaming sensor data → UDP 9010\nAcceleration (g): %.3f, %.3f, %.3f\nVertical (g): %.3f\nSensor source raw value: %d\nRemove the earbud and check whether values keep updating.",a.x,a.y,a.z,vertical,m.sensorLocation.rawValue)
            }
        }
    }
    @objc func stopMotion() { motion.stopDeviceMotionUpdates(); label.stringValue = "Stopped. TD should report stale data after one second." }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func applicationWillTerminate(_ notification: Notification) { motion.stopDeviceMotionUpdates(); connection.cancel() }
}
let application = NSApplication.shared
let delegate = App()
application.delegate = delegate
application.setActivationPolicy(.regular)
application.run()
