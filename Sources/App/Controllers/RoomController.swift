//
//  RoomController.swift
//  App
//
//  Created by Michael Redig on 2/11/20.
//

import Foundation
import Vapor
import Jobs

public class RoomController {
	var roomLimit: Int
	var myRNG = MyRNG()
	private var startingSeed: UInt64

	let roomSize: CGFloat = 720
	var roomMid: CGFloat { roomSize / 2 }

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
	var allPlayers = [String: User]()

	var spawnRoom = Room(id: 0, position: .zero, name: "Spawn Room")

	let userController: UserController

	var gameLoopTimer: Job?

	// MARK: - Lifecycle
	init(roomLimit: Int, seed: UInt64 = UInt64(CFAbsoluteTimeGetCurrent() * 10000), userController: UserController) {
		self.roomLimit = roomLimit

		self.startingSeed = seed
		self.userController = userController

		gameLoopTimer = Jobs.add(interval: .seconds(0.33333), action: { [weak self] in
			self?.gameLoop()
		})
	}

	deinit {
		gameLoopTimer?.stop()
		gameLoopTimer = nil
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

	// MARK: - Room Generation
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

	// MARK: - Player Management
	func playerDisconnected(id playerID: String) {
		guard let player = allPlayers[playerID] else { return }
		removePlayerFromCurrentRoom(player)
		allPlayers[playerID] = nil
	}

	func removePlayerFromCurrentRoom(_ player: User) {
		guard let oldRoom = rooms[player.roomID] else { return }
		oldRoom.removePlayer(player)
		if !oldRoom.occupied {
			occupiedRooms.remove(oldRoom)
			emptyRooms.insert(oldRoom)
		}
	}

	func spawn(player: User, in room: Room?, from direction: CardinalDirection?) throws {
		removePlayerFromCurrentRoom(player)
		let newRoom = room ?? spawnRoom
		occupiedRooms.insert(newRoom)
		emptyRooms.remove(newRoom)

		allPlayers[player.playerID] = player
		newRoom.addPlayer(player)

		let position: CGPoint
		if let direction = direction {
			switch direction {
			case .east:
				position = CGPoint(x: roomSize, y: roomMid)
			case .north:
				position = CGPoint(x: roomMid, y: roomSize)
			case .south:
				position = CGPoint(x: roomMid, y: 0)
			case .west:
				position = CGPoint(x: 0, y: roomMid)
			}
		} else {
			position = CGPoint(x: roomMid, y: roomMid)
		}
		player.location = position
		player.destination = position
	}

	func updatePlayerPosition(playerID: String, pulseUpdate: PositionPulseUpdate?, request: Request) {
		guard let pulseUpdate = pulseUpdate else { return }
		guard let player = allPlayers[playerID] else { return }
		player.location = pulseUpdate.position
		player.destination = pulseUpdate.destination
		_ = player.save(on: request)
	}

	// MARK: - Game logic
	private func gameLoop() {
		occupiedRooms.forEach {
			let players = $0.players
			let positionInfos: [String: PositionPulseUpdate] = players.reduce(into: [String: PositionPulseUpdate](), {
				let info = PositionPulseUpdate(position: $1.location, destination: $1.destination)
				$0[$1.playerID] = info
			})
			let message = WSMessage(messageType: .positionPulse, payload: positionInfos)

			self.sendMessageToAllPlayersOfRoom(room: $0, message: message)
		}
	}

	private func sendMessageToAllPlayersOfRoom<Payload>(room: Room, message: WSMessage<Payload>) {
		let players = room.players
		guard players.count > 0 else { return }
		let playerInfoBlob: Data
		do {
			playerInfoBlob = try message.encode()
		} catch {
			NSLog("Failed encoding player positions for pulse: \(error)")
			return
		}
		players.forEach {
			$0.webSocket?.send(playerInfoBlob)
		}
	}
}

// MARK: - Route response
extension RoomController {
	func getOverworld(_ req: Request) throws -> Future<RoomCollection> {
		return req.future(RoomCollection(rooms: rooms.mapValues { $0.representation }, roomCoordinates: roomCoordinates, spawnRoom: spawnRoom.id, seed: startingSeed))
	}

	func initializePlayer(_ req: Request) throws -> Future<UserResponse> {
		let user = try req.requireAuthenticated(User.self)

		let mid = roomMid
		return try req.content.decode(InitRepresentation.self).flatMap { initRep -> Future<UserResponse> in

			user.location = CGPoint(x: mid, y: mid)
			user.avatar = initRep.playerAvatar
			try self.spawn(player: user, in: self.rooms[user.roomID], from: nil)
			return user.update(on: req).map { $0.userResponse }
		}
	}

	func moveToRoom(_ req: Request) throws -> Future<RoomChangeInfo> {
		let user = try req.requireAuthenticated(User.self)

		return try req.content.decode(MoveRequest.self).flatMap { moveRequest -> Future<RoomChangeInfo> in
			let currentRoomID = user.roomID
			let newRoomID = moveRequest.roomID
			let currentRoom = self.rooms[currentRoomID] ?? self.spawnRoom
			guard let newRoom = self.rooms[newRoomID] else {
				// FIXME: there's probably a better error to put here
				throw HTTPError(identifier: "Invalid Room", reason: "Invalid Room")
			}

			guard let fromDirection = newRoom.direction(of: currentRoom) else {
				throw HTTPError(identifier: "Direction not valid", reason: "perhaps room is not connected")
			}
			try self.spawn(player: user, in: newRoom, from: fromDirection)
			return user.save(on: req).map { user -> RoomChangeInfo in
				return RoomChangeInfo(currentRoom: newRoom.id,
									  fromDirection: fromDirection,
									  spawnLocation: user.location,
									  otherPlayersInRoom: newRoom.players.map { $0.playerID })
			}
		}
	}
}

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
}
