//
//  ARGolfApp.swift
//  AR Golf Game
//
//  iOS App entry point for AR Golf Game
//

import SwiftUI

@main
struct ARGolfApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.automatic)
    }
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            ARGameViewController()
                .navigationTitle("AR Golf")
                .navigationBarTitleDisplayMode(.inline)
                .ignoresSafeArea(.all, edges: .bottom)
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
