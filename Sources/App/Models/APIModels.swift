//
//  APIModels.swift
//  App
//
//  Created by Michael Redig on 2/16/20.
//

import Foundation
import Vapor

// MARK: - Helper Types
struct RoomChangeInfo: Content {
	let currentRoom: Int
	let fromDirection: CardinalDirection
	let spawnLocation: CGPoint
	let otherPlayersInRoom: [String]
}

struct RoomRepresentation: Content {
	let name: String
	let position: CGPoint
	let id: Int
	let northRoomID: Int?
	let southRoomID: Int?
	let eastRoomID: Int?
	let westRoomID: Int?
}

struct RoomCollection: Content {
	let rooms: [Int: RoomRepresentation]
	let roomCoordinates: Set<CGPoint>
	let spawnRoom: Int
	let seed: UInt64
}

struct InitRepresentation: Content {
	let playerAvatar: Int
}

struct MoveRequest: Content {
	let roomID: Int
}

struct PositionPulseUpdate: Content {
	let position: CGPoint
	let destination: CGPoint
	let playerID: String?

	init(position: CGPoint, destination: CGPoint, playerID: String? = nil) {
		self.position = position
		self.destination = destination
		self.playerID = playerID
	}

	/// returns a new PositionPulseUpdate, but with the playerID value populated with the passed in value
	func setting(playerID: String) -> PositionPulseUpdate {
		PositionPulseUpdate(position: position, destination: destination, playerID: playerID)
	}
}

struct ChatMessage: Content {
	let message: String
	let playerID: String
}

struct PlayerAttack: Content {
	let attacker: String
	let hitPlayers: [String]
}
