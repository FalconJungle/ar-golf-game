//
//  PhysicsEngine.swift
//  AR Golf Game
//
//  Created on 2025-08-09
//

import Foundation
import simd

/// Physics engine for golf ball simulation with realistic physics
public class PhysicsEngine {
    
    // MARK: - Constants
    
    /// Gravity acceleration (m/s²)
    public static let gravity: Float = 9.81
    
    /// Air density at sea level (kg/m³)
    public static let airDensity: Float = 1.225
    
    /// Golf ball properties
    public struct BallProperties {
        public let mass: Float = 0.0459 // kg (regulation golf ball)
        public let radius: Float = 0.02135 // m (regulation golf ball)
        public let dragCoefficient: Float = 0.47
        public let magnusCoefficient: Float = 0.25
        public let restitution: Float = 0.8 // bounce coefficient
        public let rollingResistance: Float = 0.02
        
        public init() {}
    }
    
    // MARK: - Physics State
    
    public struct PhysicsState {
        public var position: simd_float3
        public var velocity: simd_float3
        public var angularVelocity: simd_float3
        public var isInFlight: Bool
        public var timeStep: Float
        
        public init(position: simd_float3 = simd_float3(0, 0, 0),
                   velocity: simd_float3 = simd_float3(0, 0, 0),
                   angularVelocity: simd_float3 = simd_float3(0, 0, 0),
                   isInFlight: Bool = false,
                   timeStep: Float = 0.016) {
            self.position = position
            self.velocity = velocity
            self.angularVelocity = angularVelocity
            self.isInFlight = isInFlight
            self.timeStep = timeStep
        }
    }
    
    // MARK: - Properties
    
    public let ballProperties: BallProperties
    
    // MARK: - Initialization
    
    public init(ballProperties: BallProperties = BallProperties()) {
        self.ballProperties = ballProperties
    }
    
    // MARK: - Physics Simulation
    
    /// Updates the physics state for one time step
    public func updatePhysics(state: inout PhysicsState, wind: simd_float3 = simd_float3(0, 0, 0)) {
        guard state.isInFlight else { return }
        
        // Calculate forces
        let forces = calculateForces(state: state, wind: wind)
        
        // Apply forces using Verlet integration
        let acceleration = forces / ballProperties.mass
        
        // Update velocity
        state.velocity += acceleration * state.timeStep
        
        // Update position
        state.position += state.velocity * state.timeStep
        
        // Check ground collision
        if state.position.y <= ballProperties.radius {
            handleGroundCollision(state: &state)
        }
        
        // Apply air resistance to angular velocity
        state.angularVelocity *= pow(0.99, state.timeStep * 60) // Decay factor
    }
    
    /// Calculates all forces acting on the ball
    private func calculateForces(state: PhysicsState, wind: simd_float3) -> simd_float3 {
        var totalForces = simd_float3(0, 0, 0)
        
        // Gravity
        totalForces.y -= ballProperties.mass * Self.gravity
        
        // Air resistance (drag)
        let relativeVelocity = state.velocity - wind
        let speed = length(relativeVelocity)
        
        if speed > 0.01 {
            let dragForce = calculateDragForce(velocity: relativeVelocity, speed: speed)
            totalForces += dragForce
            
            // Magnus force (spin effect)
            let magnusForce = calculateMagnusForce(velocity: relativeVelocity, angularVelocity: state.angularVelocity)
            totalForces += magnusForce
        }
        
        return totalForces
    }
    
    /// Calculates drag force
    private func calculateDragForce(velocity: simd_float3, speed: Float) -> simd_float3 {
        let area = Float.pi * ballProperties.radius * ballProperties.radius
        let dragMagnitude = 0.5 * Self.airDensity * ballProperties.dragCoefficient * area * speed * speed
        
        // Drag opposes motion
        return -normalize(velocity) * dragMagnitude
    }
    
    /// Calculates Magnus force (due to ball spin)
    private func calculateMagnusForce(velocity: simd_float3, angularVelocity: simd_float3) -> simd_float3 {
        let area = Float.pi * ballProperties.radius * ballProperties.radius
        let magnusVector = cross(angularVelocity, velocity)
        let magnusMagnitude = 0.5 * Self.airDensity * ballProperties.magnusCoefficient * area * length(magnusVector)
        
        if length(magnusVector) > 0.001 {
            return normalize(magnusVector) * magnusMagnitude
        }
        
        return simd_float3(0, 0, 0)
    }
    
    /// Handles collision with the ground
    private func handleGroundCollision(state: inout PhysicsState) {
        // Position ball on ground
        state.position.y = ballProperties.radius
        
        // Apply restitution to vertical velocity
        state.velocity.y = -state.velocity.y * ballProperties.restitution
        
        // Apply friction to horizontal velocity
        let horizontalSpeed = length(simd_float2(state.velocity.x, state.velocity.z))
        if horizontalSpeed > 0.1 {
            let frictionForce = ballProperties.rollingResistance * ballProperties.mass * Self.gravity
            let frictionDirection = normalize(simd_float2(state.velocity.x, state.velocity.z))
            let frictionDecceleration = frictionForce / ballProperties.mass
            
            let newHorizontalSpeed = max(0, horizontalSpeed - frictionDecceleration * state.timeStep)
            let speedRatio = newHorizontalSpeed / horizontalSpeed
            
            state.velocity.x *= speedRatio
            state.velocity.z *= speedRatio
        } else {
            // Stop the ball if moving very slowly
            state.velocity.x = 0
            state.velocity.z = 0
            state.isInFlight = false
        }
        
        // Reduce angular velocity on bounce
        state.angularVelocity *= 0.8
    }
    
    /// Applies an initial force to launch the ball
    public func launchBall(state: inout PhysicsState, force: simd_float3, spin: simd_float3 = simd_float3(0, 0, 0)) {
        state.velocity = force / ballProperties.mass
        state.angularVelocity = spin
        state.isInFlight = true
    }
}

// MARK: - Helper Extensions

extension PhysicsEngine {
    /// Calculates optimal launch angle for maximum distance
    public static func optimalLaunchAngle(speed: Float, wind: simd_float3 = simd_float3(0, 0, 0)) -> Float {
        // In vacuum, optimal angle is 45°, but with air resistance it's typically lower
        let windEffect = wind.y * 0.1 // Adjust for headwind/tailwind
        return (45.0 - windEffect) * Float.pi / 180.0 // Convert to radians
    }
    
    /// Calculates the range for a given launch parameters
    public func calculateRange(speed: Float, angle: Float, wind: simd_float3 = simd_float3(0, 0, 0)) -> Float {
        let initialVelocity = simd_float3(
            speed * cos(angle),
            speed * sin(angle),
            0
        )
        
        var state = PhysicsState(velocity: initialVelocity, isInFlight: true)
        
        // Simulate until ball lands
        while state.isInFlight && state.position.y >= ballProperties.radius {
            updatePhysics(state: &state, wind: wind)
        }
        
        return state.position.x
    }
}
