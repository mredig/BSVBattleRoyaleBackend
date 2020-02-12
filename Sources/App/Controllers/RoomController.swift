//
//  RoomController.swift
//  App
//
//  Created by Michael Redig on 2/11/20.
//

import Foundation

fileprivate var absoluteCurrentTime: TimeInterval {
	return Date().timeIntervalSinceReferenceDate
}

class RoomController {
	var roomLimit: Int

	var rooms = [Int: Room]()
	var occupiedRooms = Set<Room>()
	var emptyRooms = Set<Room>()
	var roomCoordinates = Set<CGPoint>()
	var allPlayers = Set<User>()

	init(roomLimit: Int, seed: UInt64 = UInt64(absoluteCurrentTime * 10000)) {
		self.roomLimit = roomLimit

		generateRooms(seed: seed)
	}

	func resetRooms() {
		rooms.removeAll()
		occupiedRooms.removeAll()
		emptyRooms.removeAll()
		roomCoordinates.removeAll()
		allPlayers.removeAll()

		// reset players
	}

	func generateRooms(seed: UInt64) {
//		User.mak
	}
}


//class RoomCollection: Codable {
//	let rooms: [Int: Room]
//	let roomCoordinates: Set<CGPoint>
//	let spawnRoom: Int
//
//	init(rooms: [Int: Room], roomCoordinates: Set<CGPoint>, spawnRoom: Int) {
//		self.rooms = rooms
//		self.roomCoordinates = roomCoordinates
//		self.spawnRoom = spawnRoom
//	}
//}
