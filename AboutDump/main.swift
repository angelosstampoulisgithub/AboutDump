//
//  main.swift
//  AboutDump
//
//  Created by Angelos Staboulis on 25/3/26.
//

import Foundation
// Where to save the file (daemon runs as root, so avoid ~)
let outputURL = URL(fileURLWithPath: "/Users/Shared/about.txt")

func runCommand(_ launchPath: String, _ arguments: [String]) -> String {
    let process = Process()
    process.launchPath = launchPath
    process.arguments = arguments

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    do {
        try process.run()
    } catch {
        return "Failed to run \(launchPath): \(error)\n"
    }

    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8) ?? ""
}

var report = ""
report += "===== sw_vers =====\n"
report += runCommand("/usr/bin/sw_vers", [])

report += "\n===== system_profiler SPHardwareDataType =====\n"
report += runCommand("/usr/sbin/system_profiler", ["SPHardwareDataType"])

report += "\n===== system_profiler SPSoftwareDataType =====\n"
report += runCommand("/usr/sbin/system_profiler", ["SPSoftwareDataType"])

report += "\n===== system_profiler SPDisplaysDataType =====\n"
report += runCommand("/usr/sbin/system_profiler", ["SPDisplaysDataType"])

do {
    try report.write(to: outputURL, atomically: true, encoding: .utf8)
} catch {
    // If write fails, try logging somewhere else
    let fallback = "/var/log/about_capture_error.log"
    let msg = "Failed to write about.txt: \(error)\n"
    try? msg.write(toFile: fallback, atomically: true, encoding: .utf8)
}
