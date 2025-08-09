//
//  Math.swift
//  AR Golf Game
//
//  Created on August 9, 2025
//

import Foundation
import simd
import CoreGraphics

/// Mathematical utility functions for AR Golf game calculations
struct MathUtils {
    
    // MARK: - Constants
    
    static let π = Float.pi
    static let twoPi = Float.pi * 2
    static let halfPi = Float.pi * 0.5
    static let degreesToRadians: Float = π / 180.0
    static let radiansToDegrees: Float = 180.0 / π
    
    // MARK: - Angle Conversions
    
    /// Convert degrees to radians
    static func degreesToRadians(_ degrees: Float) -> Float {
        return degrees * degreesToRadians
    }
    
    /// Convert radians to degrees
    static func radiansToDegrees(_ radians: Float) -> Float {
        return radians * radiansToDegrees
    }
    
    // MARK: - Distance and Vector Calculations
    
    /// Calculate distance between two SIMD3 points
    static func distance(_ point1: SIMD3<Float>, _ point2: SIMD3<Float>) -> Float {
        return length(point1 - point2)
    }
    
    /// Calculate 2D distance (ignoring Y component)
    static func distance2D(_ point1: SIMD3<Float>, _ point2: SIMD3<Float>) -> Float {
        let dx = point1.x - point2.x
        let dz = point1.z - point2.z
        return sqrt(dx * dx + dz * dz)
    }
    
    /// Normalize a vector safely (returns zero vector if input is zero)
    static func safeNormalize(_ vector: SIMD3<Float>) -> SIMD3<Float> {
        let len = length(vector)
        return len > 0.0001 ? vector / len : SIMD3<Float>(0, 0, 0)
    }
    
    /// Linear interpolation between two values
    static func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
        return a + t * (b - a)
    }
    
    /// Linear interpolation between two SIMD3 vectors
    static func lerp(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ t: Float) -> SIMD3<Float> {
        return a + t * (b - a)
    }
    
    // MARK: - Physics Calculations for Golf
    
    /// Calculate trajectory height at given distance for projectile motion
    /// - Parameters:
    ///   - distance: horizontal distance traveled
    ///   - initialVelocity: initial velocity magnitude
    ///   - launchAngle: launch angle in radians
    ///   - gravity: gravitational acceleration (positive value)
    /// - Returns: height at the given distance
    static func trajectoryHeight(distance: Float, initialVelocity: Float, launchAngle: Float, gravity: Float = 9.81) -> Float {
        let vx = initialVelocity * cos(launchAngle)
        let vy = initialVelocity * sin(launchAngle)
        
        // Avoid division by zero
        guard vx > 0.0001 else { return 0 }
        
        let time = distance / vx
        return vy * time - 0.5 * gravity * time * time
    }
    
    /// Calculate maximum range for projectile motion
    static func maxRange(initialVelocity: Float, launchAngle: Float, gravity: Float = 9.81) -> Float {
        return (initialVelocity * initialVelocity * sin(2 * launchAngle)) / gravity
    }
    
    /// Calculate optimal launch angle for maximum range (45 degrees in vacuum)
    static func optimalLaunchAngle() -> Float {
        return π / 4  // 45 degrees in radians
    }
    
    // MARK: - Clamping and Range Functions
    
    /// Clamp a value between min and max
    static func clamp<T: Comparable>(_ value: T, min: T, max: T) -> T {
        return Swift.min(Swift.max(value, min), max)
    }
    
    /// Clamp each component of a SIMD3 vector
    static func clamp(_ vector: SIMD3<Float>, min: Float, max: Float) -> SIMD3<Float> {
        return SIMD3<Float>(
            clamp(vector.x, min: min, max: max),
            clamp(vector.y, min: min, max: max),
            clamp(vector.z, min: min, max: max)
        )
    }
    
    /// Check if a value is within a range
    static func inRange<T: Comparable>(_ value: T, min: T, max: T) -> Bool {
        return value >= min && value <= max
    }
    
    // MARK: - Smoothing and Easing
    
    /// Smooth step function (3t² - 2t³)
    static func smoothStep(_ t: Float) -> Float {
        let clampedT = clamp(t, min: 0.0, max: 1.0)
        return clampedT * clampedT * (3.0 - 2.0 * clampedT)
    }
    
    /// Smoother step function (6t⁵ - 15t⁴ + 10t³)
    static func smootherStep(_ t: Float) -> Float {
        let clampedT = clamp(t, min: 0.0, max: 1.0)
        return clampedT * clampedT * clampedT * (clampedT * (clampedT * 6.0 - 15.0) + 10.0)
    }
    
    /// Exponential ease-out
    static func easeOut(_ t: Float) -> Float {
        return 1.0 - pow(2.0, -10.0 * clamp(t, min: 0.0, max: 1.0))
    }
    
    // MARK: - Geometric Calculations
    
    /// Calculate the angle between two vectors
    static func angleBetween(_ vector1: SIMD3<Float>, _ vector2: SIMD3<Float>) -> Float {
        let dot = dot(safeNormalize(vector1), safeNormalize(vector2))
        return acos(clamp(dot, min: -1.0, max: 1.0))
    }
    
    /// Project a point onto a plane defined by a point and normal
    static func projectPointOntoPlane(_ point: SIMD3<Float>, planePoint: SIMD3<Float>, planeNormal: SIMD3<Float>) -> SIMD3<Float> {
        let normal = safeNormalize(planeNormal)
        let distance = dot(point - planePoint, normal)
        return point - distance * normal
    }
    
    /// Calculate barycentric coordinates for a point in a triangle
    static func barycentricCoordinates(_ point: SIMD3<Float>, _ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>) -> SIMD3<Float> {
        let v0 = c - a
        let v1 = b - a
        let v2 = point - a
        
        let dot00 = dot(v0, v0)
        let dot01 = dot(v0, v1)
        let dot02 = dot(v0, v2)
        let dot11 = dot(v1, v1)
        let dot12 = dot(v1, v2)
        
        let invDenom = 1.0 / (dot00 * dot11 - dot01 * dot01)
        let u = (dot11 * dot02 - dot01 * dot12) * invDenom
        let v = (dot00 * dot12 - dot01 * dot02) * invDenom
        
        return SIMD3<Float>(1.0 - u - v, v, u)  // (w, u, v) where w + u + v = 1
    }
    
    // MARK: - Random Number Generation
    
    /// Generate a random float between 0 and 1
    static func randomFloat() -> Float {
        return Float.random(in: 0...1)
    }
    
    /// Generate a random float within a range
    static func randomFloat(in range: ClosedRange<Float>) -> Float {
        return Float.random(in: range)
    }
    
    /// Generate a random SIMD3 vector with components in given range
    static func randomVector3(in range: ClosedRange<Float>) -> SIMD3<Float> {
        return SIMD3<Float>(
            randomFloat(in: range),
            randomFloat(in: range),
            randomFloat(in: range)
        )
    }
    
    /// Generate a random point on a unit sphere
    static func randomPointOnSphere() -> SIMD3<Float> {
        let theta = randomFloat(in: 0...twoPi)
        let phi = acos(1 - 2 * randomFloat())
        
        return SIMD3<Float>(
            sin(phi) * cos(theta),
            sin(phi) * sin(theta),
            cos(phi)
        )
    }
}

// MARK: - Extensions

extension SIMD3 where Scalar == Float {
    
    /// Get the XZ components as a 2D vector
    var xz: SIMD2<Float> {
        return SIMD2<Float>(self.x, self.z)
    }
    
    /// Create a SIMD3 from XZ components with Y = 0
    init(xz: SIMD2<Float>, y: Float = 0) {
        self.init(xz.x, y, xz.y)
    }
    
    /// Check if the vector is approximately zero
    var isZero: Bool {
        return length(self) < 0.0001
    }
    
    /// Get a vector perpendicular to this one (in XZ plane)
    var perpendicularXZ: SIMD3<Float> {
        return SIMD3<Float>(-self.z, self.y, self.x)
    }
}

extension Float {
    
    /// Check if the float is approximately equal to another with given tolerance
    func isApproximately(_ other: Float, tolerance: Float = 0.0001) -> Bool {
        return abs(self - other) < tolerance
    }
    
    /// Wrap angle to [-π, π] range
    func wrapAngle() -> Float {
        let wrapped = self.truncatingRemainder(dividingBy: MathUtils.twoPi)
        return wrapped > MathUtils.π ? wrapped - MathUtils.twoPi : (wrapped < -MathUtils.π ? wrapped + MathUtils.twoPi : wrapped)
    }
}
