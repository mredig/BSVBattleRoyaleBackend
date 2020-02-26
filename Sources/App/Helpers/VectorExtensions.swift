//
//  VectorExtensions.swift
//  swaap
//
//  Created by Michael Redig on 11/28/19.
//  Copyright © 2019 swaap. All rights reserved.
//

// CoreGraphics isn't available on Linux, but there's partial support for CGPoint and some of its siblings.
// To get around this, I've created a typealias for CGPoint as CGVector (since CGVector doesn't exist on Linux), but
// that then results in some duplication of things that both CGVector and CGPoint have in these extensions, so I'm
// selectively compiling things on Linux

import Foundation
#if os(macOS) || os(watchOS) || os(iOS) || os(tvOS)
import CoreGraphics
#endif

extension CGSize {
	var point: CGPoint {
		CGPoint(x: width, y: height)
	}

	var midPoint: CGPoint {
		CGPoint(x: width / 2, y: height / 2)
	}

	static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
		CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
	}

	static func * (lhs: CGSize, rhs: CGSize) -> CGSize {
		CGSize(width: lhs.width * rhs.width, height: lhs.height * rhs.height)
	}

	static func + (lhs: CGSize, rhs: CGFloat) -> CGSize {
		lhs + CGSize(scalar: rhs)
	}

	static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
		CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
	}

	static func - (lhs: CGSize, rhs: CGFloat) -> CGSize {
		lhs - CGSize(scalar: rhs)
	}

	static func - (lhs: CGSize, rhs: CGSize) -> CGSize {
		lhs + -rhs
	}

	static prefix func - (size: CGSize) -> CGSize {
		CGSize(width: -size.width, height: -size.height)
	}

	init<IntNumber: BinaryInteger>(scalar: IntNumber) {
		let value = CGFloat(scalar)
		self.init(width: value, height: value)
	}

	init<FloatNumber: BinaryFloatingPoint>(scalar: FloatNumber) {
		let value = CGFloat(scalar)
		self.init(width: value, height: value)
	}
}

extension CGPoint {
	// MARK: - Point Conversion Properties
	var vector: CGVector {
		CGVector(dx: x, dy: y)
	}

	var size: CGSize {
		CGSize(width: x, height: y)
	}

	// MARK: - Point convenience Operator Overloads
	static func + (lhs: CGPoint, rhs: CGVector) -> CGPoint {
		CGPoint(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
	}

	static func - (lhs: CGPoint, rhs: CGVector) -> CGPoint {
		lhs + rhs.inverted
	}

	#if !os(Linux)
	static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
		lhs + rhs.vector
	}

	static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
		lhs + rhs.vector.inverted
	}
	#endif

	/// multiply two points together
	static func * (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
		CGPoint(x: lhs.x * rhs.x, y: lhs.y * rhs.y)
	}

	/// multiple both x and y by a single scalar
	static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
		lhs * CGPoint(x: rhs, y: rhs)
	}

	// MARK: - Point Initialization
	init<IntNumber: BinaryInteger>(scalar: IntNumber) {
		let value = CGFloat(scalar)
		self.init(x: value, y: value)
	}

	init<FloatNumber: BinaryFloatingPoint>(scalar: FloatNumber) {
		let value = CGFloat(scalar)
		self.init(x: value, y: value)
	}

	// MARK: - Point Distance
	/// calculate the distance between points
	func distance(to point: CGPoint) -> CGFloat {
		sqrt((x - point.x) * (x - point.x) + (y - point.y) * (y - point.y))
	}

	/// Determine if the distance between points is less than or equal to a comparison value. Quicker than actually calculating the distance
	func distance(to point: CGPoint, isWithin value: CGFloat) -> Bool {
		(x - point.x) * (x - point.x) + (y - point.y) * (y - point.y) <= (value * value)
	}

	/// Since float values are sloppy, it's highly likely two values that can be considered equal will not be EXACTLY equal. Adjust the `slop` to your liking or set to `0` to disable.
	func distance(to point: CGPoint, is value: CGFloat, slop: CGFloat = 0.000001) -> Bool {
		let distanceIsh = (x - point.x) * (x - point.x) + (y - point.y) * (y - point.y)
		let valueIsh = value * value
		return abs(valueIsh - distanceIsh) <= slop
	}

	// MARK: - Point Stepping
	/**
	returns a point in the direction of the `toward` CGPoint, iterated at a speed of `speed` points per second. `interval`
	is the duration of time since the last frame was updated
	*/
	func stepped(toward destination: CGPoint, interval: TimeInterval, speed: CGFloat) -> CGPoint {
		let adjustedSpeed = speed * interval.cgFloat
		let vectorBetweenPoints = vector(facing: destination)

		if distance(to: destination, isWithin: adjustedSpeed) {
			return destination
		}

		return self.stepped(withNormalizedVector: vectorBetweenPoints, interval: interval, speed: speed)
	}

	/// See `stepped` variation, just mutates self with the result
	mutating func step(toward destination: CGPoint, interval: TimeInterval, speed: CGFloat) {
		self = stepped(toward: destination, interval: interval, speed: speed)
	}

	/// Steps in the direction of the vector at a rate of `speed` distance points per second. Assumes the vector is
	/// normalized - does NOT check - it is YOUR responsibility to assure that the vector is normal!
	func stepped(withNormalizedVector vector: CGVector, interval: TimeInterval, speed: CGFloat) -> CGPoint {
		let adjustedVector = vector * speed
		return self.stepped(withVector: adjustedVector, interval: interval)
	}

	/// See `stepped` variation, just mutates self with the result
	mutating func step(withNormalizedVector vector: CGVector, interval: TimeInterval, speed: CGFloat) {
		self = stepped(withNormalizedVector: vector, interval: interval, speed: speed)
	}

	/// The vector is the rate the point will step per second. This function assumes the speed is baked into the vector.
	func stepped(withVector vector: CGVector, interval: TimeInterval) -> CGPoint {
		let adjustedVector = vector * interval.cgFloat
		return self + adjustedVector
	}

	/// See `stepped` variation, just mutates self with the result
	mutating func step(withVector vector: CGVector, interval: TimeInterval) {
		self = stepped(withVector: vector, interval: interval)
	}

	// MARK: - Point Facing
	/// Generates a vector in the direction of `facing`, optionally (default) normalized.
	func vector(facing point: CGPoint, normalized normalize: Bool = true) -> CGVector {
		let direction = vector.inverted + point.vector
		return normalize ? direction.normalized : direction
	}

	/// Determines whether the CGPoint instance is behind the passed in CGPoint,
	/// `point2`. `facing` is the `direction` that `point2` is facing.
	/// `latitude` determines angle of cone 'behind' `point2`. `1` means
	/// everything is behind `point2`, `0` means everything directly beside and
	/// behind, while `-1` means NOTHING is behind.
	func isBehind(point2: CGPoint, facing direction: CGVector, withLatitude latitude: CGFloat) -> Bool {
		let facingSelf = point2.vector(facing: self)
		let normalDirection = direction.normalized

		let dotProduct = facingSelf.dx * normalDirection.dx + facingSelf.dy * normalDirection.dy

		return dotProduct < latitude
	}

	/// Determines whether the CGPoint instance is in front of the passed in CGPoint,
	/// `point2`. `facing` is the `direction` that `point2` is facing.
	/// `latitude` determines angle of cone 'in front of' `point2`. `1` means
	/// everything is in front of `point2`, `0` means everything directly beside and
	/// behind, while `-1` means NOTHING is in front.
	func isInFront(of point2: CGPoint, facing direction: CGVector, withLatitude latitude: CGFloat) -> Bool {
		let facingSelf = point2.vector(facing: self)
		let normalDirection = direction.normalized

		let dotProduct = facingSelf.dx * normalDirection.dx + facingSelf.dy * normalDirection.dy

		return dotProduct > -latitude
	}

	// MARK: - Linear Interpolation
	func interpolation(to point: CGPoint, location: CGFloat, clipped: Bool = true) -> CGPoint {
		let location = clipped ? max(0, min(1, location)) : location
		let difference = (point - self) * location
		return self + difference
	}
}

extension CGPoint: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(x)
		hasher.combine(y)
	}
}

#if !os(Linux)
extension CGAffineTransform {
	var offset: CGPoint {
		CGPoint(x: tx, y: ty)
	}
}
#endif

#if os(Linux)
typealias CGVector = CGPoint

extension CGPoint {
	var dx: CGFloat {
		get { x }
		set { x = newValue }
	}
	var dy: CGFloat {
		get { y }
		set { y = newValue }
	}

	init(dx: CGFloat, dy: CGFloat) {
		self.init(x: dx, y: dy)
	}
}
#endif

extension CGVector {
	var normalized: CGVector {
		guard !(dx == dy && dx == 0) else { return CGVector(dx: 0, dy: 1) }
		let distance = sqrt(dx * dx + dy * dy)
		return CGVector(dx: dx / distance, dy: dy / distance)
	}

	var inverted: CGVector {
		CGVector(dx: -dx, dy: -dy)
	}

	var point: CGPoint {
		CGPoint(x: dx, y: dy)
	}

	var isNormal: Bool {
		CGPoint.zero.distance(to: self.point, is: 1.0)
	}

	#if !os(Linux)
	static func + (lhs: CGVector, rhs: CGVector) -> CGVector {
		CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
	}

	static func * (lhs: CGVector, rhs: CGFloat) -> CGVector {
		CGVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs)
	}
	#endif

	/// 0 is facing right. Moves CCW
	init(fromRadian radian: CGFloat) {
		self.init(dx: cos(radian), dy: sin(radian))
	}

	/// 0 is facing right. Moves CCW
	init(fromDegree degree: CGFloat) {
		self.init(fromRadian: degree * (CGFloat.pi / 180))
	}

	#if !os(Linux)
	init<IntNumber: BinaryInteger>(scalar: IntNumber) {
		let value = CGFloat(scalar)
		self.init(dx: value, dy: value)
	}

	init<FloatNumber: BinaryFloatingPoint>(scalar: FloatNumber) {
		let value = CGFloat(scalar)
		self.init(dx: value, dy: value)
	}
	#endif
}

#if !os(Linux)
extension CGVector: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(dx)
		hasher.combine(dy)
	}
}
#endif

extension CGRect {
	var maxXY: CGPoint {
		CGPoint(x: maxX, y: maxY)
	}

	var midPoint: CGPoint {
		CGPoint(x: midX, y: midY)
	}

	init<FloatNumber: BinaryFloatingPoint>(scalarOrigin: FloatNumber, scalarSize: FloatNumber) {
		self.init(origin: CGPoint(scalar: scalarOrigin), size: CGSize(scalar: scalarSize))
	}
}

extension Double {
	var cgFloat: CGFloat { CGFloat(self) }
}

extension CGFloat {
	static var degToRadFactor = CGFloat.pi / 180
	static var radToDegFactor = 180 / CGFloat.pi

	var double: Double { Double(self) }
}

extension ClosedRange where Bound: BinaryFloatingPoint {
	/// In a range, the value of a given relative location between bounds. For example, in the range `20...40`, the point `0.5` would be `30`
	func interpolated(at point: Double, clipped: Bool = true) -> Bound {
		let point = clipped ? Swift.max(0, Swift.min(1, point)) : point

		let normalUpper = upperBound - lowerBound
		let tValue = normalUpper * Bound(point)

		return tValue + lowerBound
	}

	/// In a range, the relative location of a value between bounds. For example, if a range were `20...40`, the value `30` would be `0.5`
	func linearPoint(of value: Bound, clipped: Bool = true) -> Double {
		let normalUpper = Double(upperBound) - Double(lowerBound)
		let normalValue = Double(value) - Double(lowerBound)
		return clipped ? Swift.min(Swift.max(normalValue / normalUpper, 0), 1) : normalValue / normalUpper
	}
}
