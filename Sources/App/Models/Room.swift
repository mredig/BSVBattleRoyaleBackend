//
//  Room.swift
//  MapVis
//
//  Created by Michael Redig on 2/1/20.
//  Copyright © 2020 Red_Egg Productions. All rights reserved.
//

import Foundation
#if os(macOS)
import CoreGraphics
#endif

class Room {
	let name: String
	var position: CGPoint
	let id: Int
	var rooms = [CardinalDirection: Room]()

	var players = Set<User>()
	var occupied = false

	let doodadSeed: UInt64
	var doodads: [Doodad] = []

	var contents: RoomContents {
		RoomContents(doodads: doodads.map { $0.representation })
	}

	var connectedDirections: [CardinalDirection] {
		Array(rooms.keys).sorted()
	}

	init(id: Int, position: CGPoint = .zero, name: String, doodadSeed: UInt64) {
		self.id = id
		self.position = position
		self.name = name
		self.doodadSeed = doodadSeed
	}

	func connect(to room: Room, through direction: CardinalDirection) {
		guard rooms[direction] == nil else { fatalError("Room \(name) already connected in \(direction) to \(rooms[direction]!.name)")}
		let newRoomPos = position.one(in: direction)

		rooms[direction] = room
		if room.rooms[direction.opposite] != self {
			room.position = newRoomPos
			room.connect(to: self, through: direction.opposite)
		}
	}

	func addPlayer(_ player: User) {
		players.insert(player)
		player.roomID = id
		occupied = !players.isEmpty
		setupDoodads()
	}

	func removePlayer(_ player: User) {
		players.remove(player)
		occupied = !players.isEmpty
	}

	func direction(of room: Room) -> CardinalDirection? {
		for (direction, connected) in rooms {
			if connected == room {
				return direction
			}
		}
		return nil
	}

	func setupDoodads() {
		guard doodads.count == 0 else { return }
		print("generating doodads for \(name)")
		let thisRNG = MyRNG(seed: doodadSeed + UInt64(id))
		let doodadsToGenerate = 5 + thisRNG.randomInt(max: 10)

		while doodads.count < doodadsToGenerate {
			let posX = thisRNG.randomInt(max: Int(RoomController.roomSize))
			let posY = thisRNG.randomInt(max: Int(RoomController.roomSize))
			let position = CGPoint(x: posX, y: posY)

			let sizeMax = BoxDoodad.maxSize.width - BoxDoodad.minSize.width
			let sizeRan = thisRNG.randomInt(max: Int(sizeMax))
			let size = CGSize(scalar: sizeRan) + BoxDoodad.minSize

			let floatGranularity: CGFloat = 10000
			let rotationRangeInt = Int(CGFloat.pi * 2 * floatGranularity)
			let rotationRandom = CGFloat(thisRNG.randomInt(max: rotationRangeInt)) / floatGranularity

			let tempbox = BoxDoodad(position: position, size: size, zRotation: rotationRandom, id: doodads.count)

			guard BoxDoodad.positioningIsValid(for: tempbox, otherDoodads: doodads) else { continue }

			doodads.append(tempbox)
		}

		doodads.forEach { print($0) }
	}
}

extension Room: CustomStringConvertible {
	var description: String {
		"Room: \(name) id: \(id) - connected to \(rooms.map { $0.value.id } )"
	}
}

extension Room: Hashable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
		hasher.combine(id)
	}
}

extension Room: Equatable {
	static func == (lhs: Room, rhs: Room) -> Bool {
		lhs.id == rhs.id &&
			lhs.position == rhs.position &&
			lhs.rooms == rhs.rooms &&
			lhs.name == rhs.name &&
			lhs.players == rhs.players &&
			lhs.occupied == rhs.occupied
	}
}

extension Room {
	var representation: RoomRepresentation {
		let rep = RoomRepresentation(name: name, position: position, id: id, northRoomID: rooms[.north]?.id, southRoomID: rooms[.south]?.id, eastRoomID: rooms[.east]?.id, westRoomID: rooms[.west]?.id)
		return rep
	}
}
