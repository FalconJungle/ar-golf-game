//
//  MacApp.swift
//  ARGolfGame
//
//  Created on 8/9/25.
//

import SwiftUI
import SceneKit
import AVFoundation

@main
struct ARGolfGameApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    requestCameraPermission()
                }
        }
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    print("Camera access granted")
                } else {
                    print("Camera access denied")
                }
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        MacGameViewController()
            .navigationTitle("AR Golf Game")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        // Settings action
                    }
                }
            }
    }
}

#Preview {
    ContentView()
}
