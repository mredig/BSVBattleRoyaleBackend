//
//  VectorExtensions.swift
//  swaap
//
//  Created by Michael Redig on 11/28/19.
//  Copyright © 2019 swaap. All rights reserved.
//

import Foundation
#if os(macOS)
import CoreGraphics
#endif

extension CGSize {
	static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
		CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
	}

	static func + (lhs: CGSize, rhs: CGFloat) -> CGSize {
		CGSize(width: lhs.width + rhs, height: lhs.height + rhs)
	}

	var toPoint: CGPoint {
		CGPoint(x: width, y: height)
	}
}

extension CGPoint {
	static func + (lhs: CGPoint, rhs: CGVector) -> CGPoint {
		CGPoint(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
	}

	/**
	multiply two points together
	*/
	static func * (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
		CGPoint(x: lhs.x * rhs.x, y: lhs.y * rhs.y)
	}

	/**
	multiple both x and y by a single scalar
	*/
	static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
		CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
	}

	func distance(to point: CGPoint) -> CGFloat {
		sqrt((x - point.x) * (x - point.x) + (y - point.y) * (y - point.y))
	}

	func distance(to point: CGPoint, isWithin value: CGFloat) -> Bool {
		(x - point.x) * (x - point.x) + (y - point.y) * (y - point.y) <= (value * value)
	}

	/**
	returns a point in the direction of the `toward` CGPoint, iterated at a speed of `speed` points per second. `interval`
	is the duration of time since the last frame was updated
	*/
	func stepped(toward destination: CGPoint, interval: TimeInterval, speed: CGFloat) -> CGPoint {
		let adjustedSpeed = speed * CGFloat(interval)
		let vectorBetweenPoints = vector(facing: destination)
		let adjustedVector = vectorBetweenPoints * adjustedSpeed

		if distance(to: destination, isWithin: adjustedSpeed) {
			return destination
		}

		return self + adjustedVector
	}

	/// See `stepped`, just mutates self with the result
	mutating func step(toward destination: CGPoint, interval: TimeInterval, speed: CGFloat) {
		self = stepped(toward: destination, interval: interval, speed: speed)
	}

	var vector: CGVector {
		CGVector(dx: x, dy: y)
	}

	func vector(facing point: CGPoint, normalized normalize: Bool = true) -> CGVector {
		let direction = vector.inverted + point.vector
		return normalize ? direction.normalized : direction
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
	#if !os(Linux)
	static func + (lhs: CGVector, rhs: CGVector) -> CGVector {
		CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
	}

	static func * (lhs: CGVector, rhs: CGFloat) -> CGVector {
		CGVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs)
	}
	#endif

	var normalized: CGVector {
		guard !(dx == dy && dx == 0) else { return CGVector(dx: 0, dy: 1) }
		let distance = sqrt(dx * dx + dy * dy)
		return CGVector(dx: dx / distance, dy: dy / distance)
	}

	var inverted: CGVector {
		CGVector(dx: -dx, dy: -dy)
	}
}

extension CGRect {
	var maxXY: CGPoint {
		CGPoint(x: maxX, y: maxY)
	}
}
