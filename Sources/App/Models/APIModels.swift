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

struct PlayerInitRepresentation: Content {
	let playerAvatar: Int
	let respawn: Bool
}

struct MoveRequest: Content {
	let roomID: Int
}

struct PositionUpdate: Content, Hashable {
	let position: CGPoint
	let trajectory: CGVector
	let playerID: String?

	init(position: CGPoint, trajectory: CGVector, playerID: String? = nil) {
		self.position = position
		self.trajectory = trajectory
		self.playerID = playerID
	}

	/// returns a new PositionPulseUpdate, but with the playerID value populated with the passed in value
	func setting(playerID: String) -> PositionUpdate {
		PositionUpdate(position: position, trajectory: trajectory, playerID: playerID)
	}
}

struct PlayerHealthUpdate: Content, Hashable {
	let currentHP: Int
	let maxHP: Int
}

struct PulseUpdate: Content, Hashable {
	let playerID: String
	let positionUpdate: PositionUpdate
	let health: PlayerHealthUpdate
}

struct ChatMessage: Content {
	let message: String
	let playerID: String
}

struct PlayerAttack: Content {
	let attacker: String
	let attackContacts: [AttackContact]
}

struct AttackContact: Content {
	let victim: String
	let vector: CGVector
	let strength: CGFloat
}
