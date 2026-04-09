import SwiftUI

@main
struct FidgetPixApp: App {
    var body: some Scene {
        WindowGroup {
            CanvasOverlayView()
        }
        .windowResizability(.contentSize)
    }
}
