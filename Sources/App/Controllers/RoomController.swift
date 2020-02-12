//
//  RoomController.swift
//  App
//
//  Created by Michael Redig on 2/11/20.
//

import Foundation



class RoomController {
	var roomLimit: Int
	var myRNG = MyRNG()

	private var _rooms: [Int: Room]?
	var rooms: [Int: Room] {
		get {
			if _rooms == nil {
				generateRooms(seed: self.startingSeed)
			}
			return _rooms!
		}
		set {
			_rooms = newValue
		}
	}
	var occupiedRooms = Set<Room>()
	var emptyRooms = Set<Room>()
	var roomCoordinates = Set<CGPoint>()
	var allPlayers = Set<User>()

	private var startingSeed: UInt64
	let userController: UserController

	init(roomLimit: Int, seed: UInt64 = UInt64(CFAbsoluteTimeGetCurrent() * 10000), userController: UserController) {
		self.roomLimit = roomLimit

		self.startingSeed = seed
		self.userController = userController
	}

	func resetRooms() {
		_rooms = [Int: Room]()
		occupiedRooms.removeAll()
		emptyRooms.removeAll()
		roomCoordinates.removeAll()
		allPlayers.removeAll()

		// reset players
		do {
			try userController.resetPlayerRooms()
		} catch {
			print("There was an error resetting player rooms: \(error)")
		}
	}

	func generateRooms(seed: UInt64) {
		resetRooms()



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
