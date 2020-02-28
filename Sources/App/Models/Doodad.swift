//
//  Doodad.swift
//  App
//
//  Created by Michael Redig on 2/28/20.
//

import Foundation

protocol Doodad {
	var id: Int { get }
	var type: String { get }
	var position: CGPoint { get }
	var size: CGSize { get }
	var zRotation: CGFloat { get }
	var radius: CGFloat { get }

	var representation: DoodadRepresentation { get }

	static var maxSize: CGSize { get }
	static var minSize: CGSize { get }

	static func positioningOverlapsAnything(for doodad: Doodad, otherDoodads: [Doodad]) -> Bool
	static func positioningIsValid(for doodad: Doodad, otherDoodads: [Doodad]) -> Bool
}

extension Doodad {
	var radius: CGFloat {
		max(size.width, size.height) / 2
	}

	var representation: DoodadRepresentation {
		DoodadRepresentation(id: id, type: type, position: position, size: size, zRotation: zRotation)
	}

	static func positioningOverlapsAnything(for doodad: Doodad, otherDoodads: [Doodad]) -> Bool {
		for other in otherDoodads {
			let minDistance = doodad.radius + other.radius
			guard !doodad.position.distance(to: other.position, isWithin: minDistance) else { return false }
		}

		let doorPositions = [
			CGPoint(x: 0, y: RoomController.roomMid),
			CGPoint(x: RoomController.roomMid, y: RoomController.roomSize),
			CGPoint(x: RoomController.roomSize, y: RoomController.roomMid),
			CGPoint(x: RoomController.roomMid, y: 0)
		]
		for doorPosition in doorPositions {
			guard !doorPosition.distance(to: doodad.position, isWithin: doodad.radius + 150) else { return false}
		}
		return true
	}

	static func positioningIsValid(for doodad: Doodad, otherDoodads: [Doodad]) -> Bool {
		positioningOverlapsAnything(for: doodad, otherDoodads: otherDoodads)
	}
}

struct BoxDoodad: Doodad {
	let id: Int
	let position: CGPoint
	let size: CGSize
	let zRotation: CGFloat
	var type: String {
		"\(Swift.type(of: self))"
	}

	static let maxSize = CGSize(scalar: 96)
	static let minSize = CGSize(scalar: 16)
}
