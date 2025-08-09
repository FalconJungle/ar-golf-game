//
//  HomeView.swift
//  AR Golf Game
//
//  Created on 08/09/2025.
//

import SwiftUI
import ARKit

struct HomeView: View {
    @State private var isARSessionActive = false
    @State private var showingGameSetup = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Logo/Title
                VStack(spacing: 10) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("AR Golf Game")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .padding(.top, 50)
                
                Spacer()
                
                // Main Menu Buttons
                VStack(spacing: 20) {
                    // Start Game Button
                    Button(action: {
                        showingGameSetup = true
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Game")
                        }
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    
                    // Practice Mode Button
                    Button(action: {
                        // Navigate to practice mode
                    }) {
                        HStack {
                            Image(systemName: "target")
                            Text("Practice Mode")
                        }
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green, lineWidth: 2)
                        )
                        .cornerRadius(12)
                    }
                    
                    // Settings Button
                    Button(action: {
                        // Navigate to settings
                    }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Settings")
                        }
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // AR Capability Check
                HStack {
                    Image(systemName: ARWorldTrackingConfiguration.isSupported ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(ARWorldTrackingConfiguration.isSupported ? .green : .red)
                    
                    Text(ARWorldTrackingConfiguration.isSupported ? "AR Ready" : "AR Not Supported")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingGameSetup) {
            GameSetupView()
        }
    }
}

// Placeholder for Game Setup View
struct GameSetupView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Game Setup")
                    .font(.largeTitle)
                    .padding()
                
                Text("Configure your AR golf experience")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Game setup options will be implemented here")
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
