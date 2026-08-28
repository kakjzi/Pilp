#!/usr/bin/env swift

import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: make-icns.swift <AppIcon.appiconset> <output.icns>\n", stderr)
    exit(1)
}

let iconset = URL(fileURLWithPath: CommandLine.arguments[1])
let output = URL(fileURLWithPath: CommandLine.arguments[2])
let entries = [
    ("icp4", "icon_16x16.png"),
    ("icp5", "icon_32x32.png"),
    ("icp6", "icon_32x32@2x.png"),
    ("ic07", "icon_128x128.png"),
    ("ic08", "icon_256x256.png"),
    ("ic09", "icon_512x512.png"),
    ("ic10", "icon_512x512@2x.png")
]

var body = Data()
for (type, filename) in entries {
    let image = try Data(
        contentsOf: iconset.appendingPathComponent(filename)
    )
    body.append(type.data(using: .ascii)!)
    body.appendBigEndian(UInt32(image.count + 8))
    body.append(image)
}

var icon = Data("icns".utf8)
icon.appendBigEndian(UInt32(body.count + 8))
icon.append(body)
try icon.write(to: output, options: .atomic)

private extension Data {
    mutating func appendBigEndian(_ value: UInt32) {
        var bigEndian = value.bigEndian
        Swift.withUnsafeBytes(of: &bigEndian) { bytes in
            append(contentsOf: bytes)
        }
    }
}
