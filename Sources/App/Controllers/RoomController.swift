//
//  RoomController.swift
//  App
//
//  Created by Michael Redig on 2/11/20.
//

import Foundation
import Vapor

public class RoomController {
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

	var spawnRoom = Room(id: 0, position: .zero, name: "Spawn Room")

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

		spawnRoom = Room(id: 0, name: "Spawn Room")
		addRoomConnection(newRoom: spawnRoom, oldRoom: nil, direction: nil)
	}

	func generateRooms(seed: UInt64 = UInt64(CFAbsoluteTimeGetCurrent() * 10000)) {
		resetRooms()

		startingSeed = seed
		myRNG = MyRNG(seed: seed)

		let roomQueue = Queue<Room>()
		roomQueue.enqueue(spawnRoom)

		while rooms.count < roomLimit {
			guard let oldRoom = roomQueue.dequeue() else {
				print("somehow there are no valid rooms in the queue!")
				return
			}

			let possibleDirections = eligibleDirections(from: oldRoom)
			guard let newDirection = myRNG.randomChoice(from: possibleDirections) else { continue }
			let newRoom = Room(id: rooms.count, name: "Room \(rooms.count)")
			addRoomConnection(newRoom: newRoom, oldRoom: oldRoom, direction: newDirection)
			if eligibleDirections(from: newRoom).count > 0 {
				roomQueue.enqueue(newRoom)
			}
			if eligibleDirections(from: oldRoom).count > 0 {
				roomQueue.enqueue(oldRoom)
			}
		}
	}

	private func addRoomConnection(newRoom: Room, oldRoom: Room?, direction: CardinalDirection?) {
		if let oldRoom = oldRoom, let direction = direction {
			oldRoom.connect(to: newRoom, through: direction)
		}

		guard rooms[newRoom.id] == nil else { fatalError("There is somehow a duplicate room! ROOM FOR YOUR LIFE") }
		rooms[newRoom.id] = newRoom
		emptyRooms.insert(newRoom)
		roomCoordinates.insert(newRoom.position)
	}

	private func eligibleDirections(from room: Room, neighborsAllowed: Int = 1) -> [CardinalDirection] {
		let (n,e,s,w) = room.position.oneInAllDirections

		var eligibleDirections = [CardinalDirection]()
		if canAddRoom(at: n, neighborsAllowed: neighborsAllowed) {
			eligibleDirections.append(.north)
		}
		if canAddRoom(at: e, neighborsAllowed: neighborsAllowed) {
			eligibleDirections.append(.east)
		}
		if canAddRoom(at: s, neighborsAllowed: neighborsAllowed) {
			eligibleDirections.append(.south)
		}
		if canAddRoom(at: w, neighborsAllowed: neighborsAllowed) {
			eligibleDirections.append(.west)
		}

		return eligibleDirections.sorted()
	}

	private func canAddRoom(at position: CGPoint, neighborsAllowed: Int) -> Bool {
		guard !roomCoordinates.contains(position) else { return false }

		let (n,s,w,e) = position.oneInAllDirections
		let occupiedLocations = [n,s,w,e].filter { roomCoordinates.contains($0) }
		return occupiedLocations.count == neighborsAllowed
	}
}

// MARK: - Route response
extension RoomController {
	func getOverworld(_ req: Request) throws -> Future<RoomCollection> {
		return req.future(RoomCollection(rooms: rooms.mapValues { $0.representation }, roomCoordinates: roomCoordinates, spawnRoom: spawnRoom.id))
	}
}


struct RoomRepresentation: Content {
	let name: String
	let position: CGPoint
	let id: Int
	let connectedRooms: [CardinalDirection: Int]
}

struct RoomCollection: Content {
	let rooms: [Int: RoomRepresentation]
	let roomCoordinates: Set<CGPoint>
	let spawnRoom: Int

	init(rooms: [Int: RoomRepresentation], roomCoordinates: Set<CGPoint>, spawnRoom: Int) {
		self.rooms = rooms
		self.roomCoordinates = roomCoordinates
		self.spawnRoom = spawnRoom
	}
}
