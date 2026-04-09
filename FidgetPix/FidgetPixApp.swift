//
//  FidgetPixApp.swift
//  FidgetPix
//
//  Created by Jun Katagiri on 2026/04/09.
//

import SwiftUI

@main
struct FidgetPixApp: App {
    var body: some Scene {
        WindowGroup {
            CanvasOverlayView()
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1200, height: 900)
    }
}
