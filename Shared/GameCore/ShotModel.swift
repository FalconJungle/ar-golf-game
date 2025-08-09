//
//  ShotModel.swift
//  AR Golf Game
//
//  Created on 2025-08-09
//

import Foundation
import simd

/// Represents a golf shot with ballistics calculations
public struct ShotModel {
    
    // MARK: - Shot Parameters
    
    public let id: UUID
    public let timestamp: Date
    public let initialPosition: simd_float3
    public let initialVelocity: simd_float3
    public let spin: simd_float3
    public let clubType: ClubType
    public let windConditions: simd_float3
    
    // MARK: - Shot Results
    
    public private(set) var trajectory: [simd_float3]
    public private(set) var landingPosition: simd_float3?
    public private(set) var distance: Float
    public private(set) var flightTime: Float
    public private(set) var maxHeight: Float
    public private(set) var accuracy: ShotAccuracy
    
    // MARK: - Club Types
    
    public enum ClubType: String, CaseIterable, Codable {
        case driver = "Driver"
        case wood3 = "3 Wood"
        case wood5 = "5 Wood"
        case iron3 = "3 Iron"
        case iron4 = "4 Iron"
        case iron5 = "5 Iron"
        case iron6 = "6 Iron"
        case iron7 = "7 Iron"
        case iron8 = "8 Iron"
        case iron9 = "9 Iron"
        case pitchingWedge = "Pitching Wedge"
        case sandWedge = "Sand Wedge"
        case lobWedge = "Lob Wedge"
        case putter = "Putter"
        
        /// Typical loft angle in degrees
        public var loft: Float {
            switch self {
            case .driver: return 10.5
            case .wood3: return 15.0
            case .wood5: return 18.0
            case .iron3: return 20.0
            case .iron4: return 24.0
            case .iron5: return 27.0
            case .iron6: return 31.0
            case .iron7: return 35.0
            case .iron8: return 39.0
            case .iron9: return 43.0
            case .pitchingWedge: return 47.0
            case .sandWedge: return 56.0
            case .lobWedge: return 60.0
            case .putter: return 4.0
            }
        }
        
        /// Typical distance range in meters
        public var typicalDistance: ClosedRange<Float> {
            switch self {
            case .driver: return 200...280
            case .wood3: return 180...230
            case .wood5: return 160...210
            case .iron3: return 150...190
            case .iron4: return 140...175
            case .iron5: return 130...160
            case .iron6: return 120...145
            case .iron7: return 110...130
            case .iron8: return 100...115
            case .iron9: return 85...105
            case .pitchingWedge: return 70...90
            case .sandWedge: return 50...70
            case .lobWedge: return 30...50
            case .putter: return 0...30
            }
        }
        
        /// Spin characteristics
        public var spinCharacteristics: SpinCharacteristics {
            switch self {
            case .driver:
                return SpinCharacteristics(backspin: 2500, sidespin: 300)
            case .wood3, .wood5:
                return SpinCharacteristics(backspin: 3500, sidespin: 400)
            case .iron3, .iron4, .iron5:
                return SpinCharacteristics(backspin: 4500, sidespin: 500)
            case .iron6, .iron7:
                return SpinCharacteristics(backspin: 6000, sidespin: 600)
            case .iron8, .iron9:
                return SpinCharacteristics(backspin: 7500, sidespin: 700)
            case .pitchingWedge, .sandWedge:
                return SpinCharacteristics(backspin: 9000, sidespin: 800)
            case .lobWedge:
                return SpinCharacteristics(backspin: 10000, sidespin: 900)
            case .putter:
                return SpinCharacteristics(backspin: 100, sidespin: 50)
            }
        }
    }
    
    // MARK: - Supporting Types
    
    public struct SpinCharacteristics {
        public let backspin: Float // RPM
        public let sidespin: Float // RPM
        
        public init(backspin: Float, sidespin: Float) {
            self.backspin = backspin
            self.sidespin = sidespin
        }
    }
    
    public struct ShotAccuracy {
        public let targetDistance: Float
        public let actualDistance: Float
        public let lateralDeviation: Float
        public let accuracy: Float // 0.0 to 1.0
        
        public init(target: simd_float3, actual: simd_float3) {
            self.targetDistance = length(target)
            self.actualDistance = length(actual)
            self.lateralDeviation = abs(actual.x - target.x)
            
            let distanceError = abs(actualDistance - targetDistance)
            let lateralError = lateralDeviation
            let totalError = sqrt(distanceError * distanceError + lateralError * lateralError)
            
            // Accuracy decreases with error, normalized to reasonable golf standards
            self.accuracy = max(0.0, 1.0 - (totalError / 50.0))
        }
    }
    
    // MARK: - Initialization
    
    public init(position: simd_float3,
                velocity: simd_float3,
                spin: simd_float3 = simd_float3(0, 0, 0),
                clubType: ClubType,
                windConditions: simd_float3 = simd_float3(0, 0, 0),
                target: simd_float3? = nil) {
        
        self.id = UUID()
        self.timestamp = Date()
        self.initialPosition = position
        self.initialVelocity = velocity
        self.spin = spin
        self.clubType = clubType
        self.windConditions = windConditions
        
        // Initialize calculated values
        self.trajectory = []
        self.landingPosition = nil
        self.distance = 0
        self.flightTime = 0
        self.maxHeight = 0
        self.accuracy = ShotAccuracy(target: target ?? simd_float3(100, 0, 0), 
                                   actual: simd_float3(0, 0, 0))
        
        // Calculate shot ballistics
        calculateBallistics(target: target)
    }
    
    // MARK: - Ballistics Calculation
    
    private mutating func calculateBallistics(target: simd_float3?) {
        let physicsEngine = PhysicsEngine()
        var state = PhysicsEngine.PhysicsState(
            position: initialPosition,
            velocity: initialVelocity,
            angularVelocity: spin,
            isInFlight: true
        )
        
        var trajectoryPoints: [simd_float3] = []
        var timeElapsed: Float = 0
        let timeStep: Float = 0.016 // ~60 FPS
        var currentMaxHeight: Float = initialPosition.y
        
        // Simulate shot trajectory
        while state.isInFlight && timeElapsed < 15.0 { // Max 15 seconds
            trajectoryPoints.append(state.position)
            
            // Track maximum height
            currentMaxHeight = max(currentMaxHeight, state.position.y)
            
            // Update physics
            physicsEngine.updatePhysics(state: &state, wind: windConditions)
            
            timeElapsed += timeStep
            
            // Check if ball has landed
            if state.position.y <= 0 && timeElapsed > 0.1 {
                break
            }
        }
        
        // Store results
        self.trajectory = trajectoryPoints
        self.landingPosition = trajectoryPoints.last
        self.flightTime = timeElapsed
        self.maxHeight = currentMaxHeight - initialPosition.y
        
        if let landing = landingPosition {
            self.distance = length(simd_float2(landing.x - initialPosition.x, 
                                             landing.z - initialPosition.z))
            
            if let targetPos = target {
                self.accuracy = ShotAccuracy(target: targetPos, actual: landing)
            }
        }
    }
    
    // MARK: - Shot Analysis
    
    /// Provides detailed analysis of the shot
    public func analysis() -> ShotAnalysis {
        return ShotAnalysis(
            shot: self,
            carryDistance: distance,
            apexHeight: maxHeight,
            flightTime: flightTime,
            launchAngle: calculateLaunchAngle(),
            ballSpeed: length(initialVelocity),
            spinRate: length(spin),
            efficiency: calculateEfficiency()
        )
    }
    
    private func calculateLaunchAngle() -> Float {
        let horizontalSpeed = length(simd_float2(initialVelocity.x, initialVelocity.z))
        return atan2(initialVelocity.y, horizontalSpeed) * 180.0 / Float.pi
    }
    
    private func calculateEfficiency() -> Float {
        let ballSpeed = length(initialVelocity)
        let expectedDistance = clubType.typicalDistance.lowerBound + 
                             (clubType.typicalDistance.upperBound - clubType.typicalDistance.lowerBound) * 0.5
        return min(1.0, distance / expectedDistance)
    }
    
    // MARK: - Shot Comparison
    
    /// Compares this shot to ideal parameters for the club type
    public func compareToIdeal() -> ShotComparison {
        let idealDistance = (clubType.typicalDistance.lowerBound + clubType.typicalDistance.upperBound) / 2
        let idealLaunchAngle = clubType.loft * 0.7 // Rough approximation
        
        return ShotComparison(
            distanceEfficiency: distance / idealDistance,
            launchAngleAccuracy: 1.0 - abs(calculateLaunchAngle() - idealLaunchAngle) / idealLaunchAngle,
            spinAccuracy: calculateSpinAccuracy(),
            overallRating: calculateOverallRating()
        )
    }
    
    private func calculateSpinAccuracy() -> Float {
        let actualSpinRate = length(spin)
        let idealSpinRate = clubType.spinCharacteristics.backspin
        return max(0.0, 1.0 - abs(actualSpinRate - idealSpinRate) / idealSpinRate)
    }
    
    private func calculateOverallRating() -> Float {
        let comparison = compareToIdeal()
        return (comparison.distanceEfficiency + 
                comparison.launchAngleAccuracy + 
                comparison.spinAccuracy + 
                accuracy.accuracy) / 4.0
    }
}

// MARK: - Supporting Analysis Types

public struct ShotAnalysis {
    public let shot: ShotModel
    public let carryDistance: Float
    public let apexHeight: Float
    public let flightTime: Float
    public let launchAngle: Float
    public let ballSpeed: Float
    public let spinRate: Float
    public let efficiency: Float
    
    public var description: String {
        return """
        Shot Analysis:
        Club: \(shot.clubType.rawValue)
        Distance: \(String(format: "%.1f", carryDistance))m
        Launch Angle: \(String(format: "%.1f", launchAngle))°
        Ball Speed: \(String(format: "%.1f", ballSpeed))m/s
        Max Height: \(String(format: "%.1f", apexHeight))m
        Flight Time: \(String(format: "%.1f", flightTime))s
        Efficiency: \(String(format: "%.1%", efficiency))
        """
    }
}

public struct ShotComparison {
    public let distanceEfficiency: Float
    public let launchAngleAccuracy: Float
    public let spinAccuracy: Float
    public let overallRating: Float
    
    public var grade: String {
        switch overallRating {
        case 0.9...1.0: return "A+"
        case 0.8..<0.9: return "A"
        case 0.7..<0.8: return "B+"
        case 0.6..<0.7: return "B"
        case 0.5..<0.6: return "C+"
        case 0.4..<0.5: return "C"
        case 0.3..<0.4: return "D+"
        case 0.2..<0.3: return "D"
        default: return "F"
        }
    }
}

// MARK: - Codable Conformance

extension ShotModel: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, timestamp, initialPosition, initialVelocity, spin
        case clubType, windConditions, trajectory, landingPosition
        case distance, flightTime, maxHeight
    }
}

extension ShotModel.ShotAccuracy: Codable {}
extension ShotModel.SpinCharacteristics: Codable {}
