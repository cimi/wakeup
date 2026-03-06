import Cocoa
import Foundation

// MARK: - Script Execution

func runScript(at path: String, eventName: String) {
    let expanded = NSString(string: path).expandingTildeInPath
    let fm = FileManager.default

    guard fm.fileExists(atPath: expanded) else {
        fputs("[\(eventName)] script not found: \(expanded)\n", stderr)
        return
    }

    guard fm.isExecutableFile(atPath: expanded) else {
        fputs("[\(eventName)] script not executable: \(expanded)\n", stderr)
        return
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: expanded)
    process.standardOutput = FileHandle.standardOutput
    process.standardError = FileHandle.standardError

    do {
        try process.run()
        process.waitUntilExit()
        let status = process.terminationStatus
        if status != 0 {
            fputs("[\(eventName)] script exited with status \(status)\n", stderr)
        }
    } catch {
        fputs("[\(eventName)] failed to run script: \(error.localizedDescription)\n", stderr)
    }
}

// MARK: - LaunchAgent Install/Uninstall

let plistLabel = "com.github.wakeup"

func launchAgentDir() -> String {
    return NSString(string: "~/Library/LaunchAgents").expandingTildeInPath
}

func plistPath() -> String {
    return (launchAgentDir() as NSString).appendingPathComponent("\(plistLabel).plist")
}

func install() {
    let binaryPath = CommandLine.arguments[0]
    let home = NSHomeDirectory()
    let logDir = (home as NSString).appendingPathComponent("Library/Logs")

    let plist = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>Label</key>
        <string>\(plistLabel)</string>
        <key>ProgramArguments</key>
        <array>
            <string>\(binaryPath)</string>
        </array>
        <key>KeepAlive</key>
        <true/>
        <key>RunAtLoad</key>
        <true/>
        <key>StandardOutPath</key>
        <string>\(logDir)/wakeup.log</string>
        <key>StandardErrorPath</key>
        <string>\(logDir)/wakeup.error.log</string>
    </dict>
    </plist>
    """

    let agentDir = launchAgentDir()
    let fm = FileManager.default
    if !fm.fileExists(atPath: agentDir) {
        try? fm.createDirectory(atPath: agentDir, withIntermediateDirectories: true)
    }

    let dest = plistPath()
    do {
        try plist.write(toFile: dest, atomically: true, encoding: .utf8)
        print("Wrote \(dest)")
    } catch {
        fputs("Failed to write plist: \(error.localizedDescription)\n", stderr)
        exit(1)
    }

    let load = Process()
    load.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    load.arguments = ["load", dest]
    try? load.run()
    load.waitUntilExit()

    if load.terminationStatus == 0 {
        print("LaunchAgent loaded successfully.")
    } else {
        fputs("launchctl load failed with status \(load.terminationStatus)\n", stderr)
        exit(1)
    }
}

func uninstall() {
    let dest = plistPath()
    let fm = FileManager.default

    if fm.fileExists(atPath: dest) {
        let unload = Process()
        unload.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        unload.arguments = ["unload", dest]
        try? unload.run()
        unload.waitUntilExit()
        print("LaunchAgent unloaded.")

        try? fm.removeItem(atPath: dest)
        print("Removed \(dest)")
    } else {
        print("No LaunchAgent plist found at \(dest)")
    }
}

// MARK: - Main

let args = CommandLine.arguments

if args.contains("--install") {
    install()
    exit(0)
} else if args.contains("--uninstall") {
    uninstall()
    exit(0)
}

let center = NSWorkspace.shared.notificationCenter

center.addObserver(
    forName: NSWorkspace.didWakeNotification,
    object: nil,
    queue: .main
) { _ in
    runScript(at: "~/.wakeup", eventName: "wake")
}

RunLoop.main.run()
