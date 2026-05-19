//
//  ismallocscribble.swift
//  poc
//
//  Created by ruter on 19.05.26.
//

import OSLog

func ismallocscribble() async -> Bool {
    do {
        let store = try OSLogStore(scope: .currentProcessIdentifier)
        let position = store.position(date: Date().addingTimeInterval(-10))
        let entries = try store.getEntries(at: position)

        for case let entry as OSLogEntryLog in entries {
            if entry.composedMessage.contains("malloc: enabling scribbling") {
                return true
            }
        }
    } catch {
        print(error)
    }

    return false
}
