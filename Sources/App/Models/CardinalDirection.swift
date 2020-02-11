//
//  CardinalDirection.swift
//  App
//
//  Created by Michael Redig on 2/11/20.
//

import Foundation

enum CardinalDirection: Int, Comparable {
	case north
	case east
	case south
	case west

	var opposite: CardinalDirection {
		switch self {
		case .east:
			return .west
		case .west:
			return .east
		case .north:
			return .south
		case .south:
			return .north
		}
	}

	static func < (lhs: CardinalDirection, rhs: CardinalDirection) -> Bool {
		lhs.rawValue < rhs.rawValue
	}

	static func > (lhs: CardinalDirection, rhs: CardinalDirection) -> Bool {
		lhs.rawValue > rhs.rawValue
	}
}

extension CGPoint {
	func one(in direction: CardinalDirection) -> CGPoint {
		switch direction {
		case .east:
			return self + CGVector(dx: 1, dy: 0)
		case .west:
			return self + CGVector(dx: -1, dy: 0)
		case .north:
			return self + CGVector(dx: 0, dy: 1)
		case .south:
			return self + CGVector(dx: 0, dy: -1)
		}
	}

	var oneInAllDirections: (north: CGPoint, east: CGPoint, south: CGPoint, west: CGPoint) {
		(self.one(in: .north), self.one(in: .east), self.one(in: .south), self.one(in: .west))
	}
}
