//
//  Logging.swift
//  AR Golf Game
//
//  Created on August 9, 2025
//

import Foundation
import os.log

/// Centralized logging utility for the AR Golf Game
struct Logger {
    
    // MARK: - Log Categories
    
    static let game = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "ar-golf-game", category: "game")
    static let ui = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "ar-golf-game", category: "ui")
    static let network = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "ar-golf-game", category: "network")
    static let ar = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "ar-golf-game", category: "ar")
    static let physics = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "ar-golf-game", category: "physics")
    
    // MARK: - Logging Methods
    
    /// Log debug information
    static func debug(_ message: String, category: OSLog = .default, file: String = #file, function: String = #function, line: Int = #line) {
        os_log("%@", log: category, type: .debug, formatMessage(message, file: file, function: function, line: line))
    }
    
    /// Log informational messages
    static func info(_ message: String, category: OSLog = .default, file: String = #file, function: String = #function, line: Int = #line) {
        os_log("%@", log: category, type: .info, formatMessage(message, file: file, function: function, line: line))
    }
    
    /// Log warnings
    static func warning(_ message: String, category: OSLog = .default, file: String = #file, function: String = #function, line: Int = #line) {
        os_log("%@", log: category, type: .default, formatMessage(message, file: file, function: function, line: line))
    }
    
    /// Log errors
    static func error(_ message: String, category: OSLog = .default, file: String = #file, function: String = #function, line: Int = #line) {
        os_log("%@", log: category, type: .error, formatMessage(message, file: file, function: function, line: line))
    }
    
    /// Log critical errors
    static func fault(_ message: String, category: OSLog = .default, file: String = #file, function: String = #function, line: Int = #line) {
        os_log("%@", log: category, type: .fault, formatMessage(message, file: file, function: function, line: line))
    }
    
    // MARK: - Private Methods
    
    private static func formatMessage(_ message: String, file: String, function: String, line: Int) -> String {
        let filename = (file as NSString).lastPathComponent
        return "[\(filename):\(line)] \(function): \(message)"
    }
}

// MARK: - Convenience Extensions

extension Logger {
    
    /// Log game-related events
    static func gameEvent(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        info(message, category: game, file: file, function: function, line: line)
    }
    
    /// Log UI-related events
    static func uiEvent(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        info(message, category: ui, file: file, function: function, line: line)
    }
    
    /// Log AR-related events
    static func arEvent(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        info(message, category: ar, file: file, function: function, line: line)
    }
    
    /// Log physics-related events
    static func physicsEvent(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        info(message, category: physics, file: file, function: function, line: line)
    }
    
    /// Log network-related events
    static func networkEvent(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        info(message, category: network, file: file, function: function, line: line)
    }
}
