//
//  MiniMapView.swift
//  AR Golf Game
//
//  Created on 8/9/25.
//

import SwiftUI
import ARKit
import MapKit
import CoreLocation

struct MiniMapView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var courseManager = CourseManager()
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Mini-map background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .frame(width: 160, height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.8), lineWidth: 2)
                )
            
            // Map content
            Map(coordinateRegion: $mapRegion, 
                interactionModes: [],
                showsUserLocation: true,
                annotationItems: courseManager.courseElements) { element in
                MapAnnotation(coordinate: element.coordinate) {
                    CourseElementView(element: element)
                }
            }
            .frame(width: 150, height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .allowsHitTesting(false)
            
            // Course info overlay
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text("HOLE \(courseManager.currentHole)")
                        .font(.caption2)
                        .fontWeight(.bold)
                    
                    Text("PAR \(courseManager.currentPar)")
                        .font(.caption2)
                }
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1)
                
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    
                    Text("\(Int(courseManager.distanceToPin))y")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .shadow(color: .black, radius: 1)
                
                Spacer()
            }
            .padding(6)
            .frame(width: 160, height: 120, alignment: .topTrailing)
        }
        .onReceive(locationManager.$currentLocation) { location in
            if let location = location {
                mapRegion.center = location.coordinate
                courseManager.updatePlayerLocation(location.coordinate)
            }
        }
        .onAppear {
            locationManager.requestLocation()
        }
    }
}

// MARK: - Course Element View
struct CourseElementView: View {
    let element: CourseElement
    
    var body: some View {
        ZStack {
            Circle()
                .fill(element.color)
                .frame(width: elementSize, height: elementSize)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1)
                )
            
            Image(systemName: element.iconName)
                .font(.system(size: elementIconSize))
                .foregroundColor(.white)
        }
        .scaleEffect(element.isImportant ? 1.2 : 1.0)
        .shadow(color: .black.opacity(0.3), radius: 2)
    }
    
    private var elementSize: CGFloat {
        switch element.type {
        case .pin:
            return 12
        case .tee:
            return 8
        case .hazard, .sand:
            return 6
        case .fairway:
            return 4
        }
    }
    
    private var elementIconSize: CGFloat {
        elementSize * 0.6
    }
}

// MARK: - Course Element Model
struct CourseElement: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let type: CourseElementType
    let isImportant: Bool
    
    var color: Color {
        switch type {
        case .pin:
            return .red
        case .tee:
            return .blue
        case .hazard:
            return .blue.opacity(0.8)
        case .sand:
            return .yellow
        case .fairway:
            return .green
        }
    }
    
    var iconName: String {
        switch type {
        case .pin:
            return "flag.fill"
        case .tee:
            return "circle.fill"
        case .hazard:
            return "drop.fill"
        case .sand:
            return "circle.dotted"
        case .fairway:
            return "leaf.fill"
        }
    }
}

enum CourseElementType {
    case pin
    case tee
    case hazard
    case sand
    case fairway
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1.0 // Update every meter
    }
    
    func requestLocation() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        default:
            // Handle denied/restricted cases
            simulateLocation()
        }
    }
    
    private func startLocationUpdates() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            return
        }
        
        locationManager.startUpdatingLocation()
    }
    
    private func simulateLocation() {
        // Simulate a golf course location for demo purposes
        let simulatedLocation = CLLocation(
            latitude: 37.7749, // San Francisco area
            longitude: -122.4194
        )
        currentLocation = simulatedLocation
    }
}

// MARK: - Location Manager Delegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        simulateLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            simulateLocation()
        default:
            break
        }
    }
}

// MARK: - Course Manager
class CourseManager: ObservableObject {
    @Published var courseElements: [CourseElement] = []
    @Published var currentHole: Int = 1
    @Published var currentPar: Int = 4
    @Published var distanceToPin: Double = 150.0
    
    private var playerLocation: CLLocationCoordinate2D?
    
    init() {
        generateCourseElements()
    }
    
    func updatePlayerLocation(_ location: CLLocationCoordinate2D) {
        playerLocation = location
        updateDistanceToPin()
    }
    
    private func updateDistanceToPin() {
        guard let playerLocation = playerLocation,
              let pinElement = courseElements.first(where: { $0.type == .pin }) else {
            return
        }
        
        let playerCLLocation = CLLocation(latitude: playerLocation.latitude, longitude: playerLocation.longitude)
        let pinCLLocation = CLLocation(latitude: pinElement.coordinate.latitude, longitude: pinElement.coordinate.longitude)
        
        // Convert to yards (1 meter ≈ 1.094 yards)
        distanceToPin = playerCLLocation.distance(from: pinCLLocation) * 1.094
    }
    
    private func generateCourseElements() {
        // Generate sample course elements for demonstration
        let baseLatitude = 37.7749
        let baseLongitude = -122.4194
        
        // Tee box
        courseElements.append(CourseElement(
            coordinate: CLLocationCoordinate2D(latitude: baseLatitude, longitude: baseLongitude),
            type: .tee,
            isImportant: true
        ))
        
        // Fairway points
        for i in 1...3 {
            courseElements.append(CourseElement(
                coordinate: CLLocationCoordinate2D(
                    latitude: baseLatitude + Double(i) * 0.001,
                    longitude: baseLongitude + Double(i) * 0.001
                ),
                type: .fairway,
                isImportant: false
            ))
        }
        
        // Hazards
        courseElements.append(CourseElement(
            coordinate: CLLocationCoordinate2D(latitude: baseLatitude + 0.002, longitude: baseLongitude - 0.001),
            type: .hazard,
            isImportant: false
        ))
        
        // Sand trap
        courseElements.append(CourseElement(
            coordinate: CLLocationCoordinate2D(latitude: baseLatitude + 0.003, longitude: baseLongitude + 0.002),
            type: .sand,
            isImportant: false
        ))
        
        // Pin (hole)
        courseElements.append(CourseElement(
            coordinate: CLLocationCoordinate2D(latitude: baseLatitude + 0.004, longitude: baseLongitude + 0.003),
            type: .pin,
            isImportant: true
        ))
        
        // Simulate changing hole info periodically
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.simulateNextHole()
        }
    }
    
    private func simulateNextHole() {
        currentHole = (currentHole % 18) + 1
        currentPar = [3, 4, 4, 5, 3, 4, 4, 5, 4][Int.random(in: 0..<9)]
        distanceToPin = Double.random(in: 75...250)
    }
}

// MARK: - Preview
struct MiniMapView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.blue.opacity(0.3) // Simulate AR background
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    MiniMapView()
                        .padding(.trailing, 20)
                        .padding(.top, 50)
                }
                Spacer()
            }
        }
    }
}
