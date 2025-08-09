//
//  SettingsView.swift
//  AR Golf Game
//
//  Created on August 9, 2025
//

import SwiftUI

struct SettingsView: View {
    // MARK: - State Variables
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("musicEnabled") private var musicEnabled = true
    @AppStorage("dominantHand") private var dominantHand = "Right"
    @AppStorage("trackingSensitivity") private var trackingSensitivity = 0.5
    @AppStorage("cameraMode") private var cameraMode = "Standard"
    
    // MARK: - Constants
    private let dominantHandOptions = ["Left", "Right"]
    private let cameraModeOptions = ["Standard", "Wide Angle", "Telephoto"]
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Audio Settings Section
                Section(header: Text("Audio Settings")) {
                    Toggle("Sound Effects", isOn: $soundEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                    
                    Toggle("Background Music", isOn: $musicEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                
                // MARK: - Gameplay Settings Section
                Section(header: Text("Gameplay Settings")) {
                    // Dominant Hand Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dominant Hand")
                            .font(.headline)
                        
                        Picker("Dominant Hand", selection: $dominantHand) {
                            ForEach(dominantHandOptions, id: \.self) { hand in
                                Text(hand).tag(hand)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.vertical, 4)
                }
                
                // MARK: - AR Settings Section
                Section(header: Text("AR Settings")) {
                    // Tracking Sensitivity Slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Tracking Sensitivity")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(trackingSensitivity * 100))%")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Low")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: $trackingSensitivity, in: 0...1, step: 0.1)
                                .accentColor(.blue)
                            
                            Text("High")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // Camera Mode Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Camera Mode")
                            .font(.headline)
                        
                        Picker("Camera Mode", selection: $cameraMode) {
                            ForEach(cameraModeOptions, id: \.self) { mode in
                                Text(mode).tag(mode)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding(.vertical, 4)
                }
                
                // MARK: - About Section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Reset to Default Settings") {
                        resetToDefaults()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Methods
    private func resetToDefaults() {
        soundEnabled = true
        musicEnabled = true
        dominantHand = "Right"
        trackingSensitivity = 0.5
        cameraMode = "Standard"
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .previewDisplayName("Settings View")
    }
}
