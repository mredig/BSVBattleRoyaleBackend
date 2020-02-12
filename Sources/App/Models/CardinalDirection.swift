//
//  CardinalDirection.swift
//  App
//
//  Created by Michael Redig on 2/11/20.
//

import Foundation
import Vapor

enum CardinalDirection: Int, Comparable, Codable, Hashable {
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

	var stringValue: String {
		switch self {
		case .north:
			return "north"
		case .south:
			return "south"
		case .east:
			return "east"
		case .west:
			return "west"
		}
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let rawValue = try container.decode(String.self)
		let lcValue = rawValue.lowercased()

		guard let decoded = CardinalDirection(stringValue: lcValue) else {
			throw VaporError.init(identifier: "Direction Decoding Error", reason: "\(lcValue) did not match any cardinal directions.")
		}
		self = decoded
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(stringValue)
	}

	init?(stringValue: String) {
		switch stringValue.lowercased() {
		case "north":
			self = .north
		case "south":
			self = .south
		case "east":
			self = .east
		case "west":
			self = .west
		default:
			return nil
		}
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(stringValue)
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
