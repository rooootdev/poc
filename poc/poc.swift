//
//  poc.swift
//  poc
//
//  Created by ruter on 18.05.26.
//

import SwiftUI
import Combine

@MainActor
class appinfo: ObservableObject {
    @Published var mallocscribble = false
    @Published var debugged = false

    func load() {
        Task {
            self.mallocscribble = await ismallocscribble()
            self.debugged = isdebugged()
            print("(poc) mallocscribble is \(self.mallocscribble ? "enabled" : "disabled")")
            print("(poc) process is \(self.debugged ? "debugged" : "not debugged")")
        }
    }
}

@main
struct poc: App {
    @StateObject private var state = appinfo()
    
    var body: some Scene {
        WindowGroup {
            jpwnxlview()
                .environmentObject(state)
                .task {
                    state.load()
                }
        }
    }
}
