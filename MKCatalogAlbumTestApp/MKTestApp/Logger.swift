//
//  Logger.swift
//  MKTestApp
//
//  Created by David Deller on 5/20/25.
//

import Foundation
import OSLog

extension Logger {
    /// From Apple docs:
    /// > The string that identifies the subsystem that emits signposts. Typically, you use the same value as your app’s bundle ID. For more information, see CFBundleIdentifier.
    private static var subsystem = Bundle.main.bundleIdentifier!

    static let view = Logger(subsystem: subsystem, category: "view")
    static let database = Logger(subsystem: subsystem, category: "database")
    static let audio = Logger(subsystem: subsystem, category: "audio")
    static let scanning = Logger(subsystem: subsystem, category: "scanning")
    static let commerce = Logger(subsystem: subsystem, category: "commerce")
    static let utility = Logger(subsystem: subsystem, category: "utility")
    static let simulation = Logger(subsystem: subsystem, category: "simulation")
    static let other = Logger(subsystem: subsystem, category: "other")
}
