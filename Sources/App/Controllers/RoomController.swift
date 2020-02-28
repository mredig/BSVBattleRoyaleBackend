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

	static let roomSize: CGFloat = 720
	static var roomMid: CGFloat { roomSize / 2 }

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
	var roomCoordinates = [CGPoint: Room]()
	var allPlayers = [String: User]()

	var spawnRoom = Room(id: 0, position: .zero, name: "Spawn Room", doodadSeed: 0)

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

		spawnRoom = Room(id: 0, name: "Spawn Room", doodadSeed: 0)
		addRoomConnection(newRoom: spawnRoom, oldRoom: nil, direction: nil)
	}

	// MARK: - Room Generation
	func generateRooms(seed: UInt64 = UInt64(CFAbsoluteTimeGetCurrent() * 10000)) {
		resetRooms()

		startingSeed = seed
		print("Generating with seed: \(seed)")
		myRNG = MyRNG(seed: seed)

		let roomQueue = Queue<Room>()
		roomQueue.enqueue(spawnRoom)

		// part 1
		let part1Rooms = Int(Double(roomLimit) * 0.85)
		while rooms.count < part1Rooms {
			guard let oldRoom = roomQueue.dequeue() else {
				print("somehow there are no valid rooms in the queue!")
				return
			}

			let possibleDirections = eligibleDirections(from: oldRoom)
			guard let newDirection = myRNG.randomChoice(from: possibleDirections) else { continue }
			let newRoom = Room(id: rooms.count, name: "Room \(rooms.count)", doodadSeed: seed)
			addRoomConnection(newRoom: newRoom, oldRoom: oldRoom, direction: newDirection)
			if eligibleDirections(from: newRoom).count > 0 {
				roomQueue.enqueue(newRoom)
			}
			if eligibleDirections(from: oldRoom).count > 0 {
				roomQueue.enqueue(oldRoom)
			}
		}

		// part 2
		while rooms.count < roomLimit {
			guard let (_, oldRoom) = myRNG.randomChoice(from: rooms) else {
				print("somehow there are no rooms!")
				return
			}

			let possibleDirections = eligibleDirections(from: oldRoom, neighborsAllowed: 2)
			guard let newDirection = myRNG.randomChoice(from: possibleDirections) else { continue }
			let newRoom = Room(id: rooms.count, name: "Room \(rooms.count)", doodadSeed: seed)
			addRoomConnection(newRoom: newRoom, oldRoom: oldRoom, direction: newDirection)
			if myRNG.randomInt(max: 100) < 75 {
				// connect the second door
				guard let otherRoom = neighboringRooms(to: newRoom).first(where: { $0 != oldRoom }) else { continue }
				guard let otherDirection = direction(to: otherRoom, from: newRoom) else { continue }
				newRoom.connect(to: otherRoom, through: otherDirection)
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
		roomCoordinates[newRoom.position] = newRoom
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
		guard roomCoordinates[position] == nil else { return false }

		let (n,s,w,e) = position.oneInAllDirections
		let occupiedLocations = [n,s,w,e].filter { roomCoordinates[$0] != nil }
		return occupiedLocations.count == neighborsAllowed
	}

	private func neighboringRooms(to room: Room) -> [Room] {
		let pos = room.position
		let (n,s,w,e) = pos.oneInAllDirections
		return [n,s,w,e].compactMap { roomCoordinates[$0] }
	}

	private func direction(to destination: Room, from source: Room) -> CardinalDirection? {
		guard destination.position.distance(to: source.position, isWithin: 1.01) else { return nil }

		if destination.position.y == source.position.y {
			if destination.position.x < source.position.x {
				return .west
			} else {
				return .east
			}
		} else if destination.position.x == source.position.x {
			if destination.position.y < source.position.y {
				return .south
			} else {
				return .north
			}
		}
		return nil
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

	func spawn(player: User, in room: Room?, from direction: CardinalDirection?) {
		removePlayerFromCurrentRoom(player)
		let newRoom = room ?? spawnRoom
		occupiedRooms.insert(newRoom)
		emptyRooms.remove(newRoom)

		// fallback in case i can't somehow maintain the same player instance in the future
//		if let webSocket = allPlayers[player.playerID]?.webSocket, player.webSocket == nil {
//			player.webSocket = webSocket
//		}
		allPlayers[player.playerID] = player
		newRoom.addPlayer(player)

		let roomSize = Self.roomSize
		let roomMid = Self.roomMid

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
			player.location = position
		}
		player.trajectory = .zero
	}

	func updatePlayerPulse(playerID: String, pulseUpdate: PositionUpdate?, request: Request) {
		guard let pulseUpdate = pulseUpdate else { return }
		guard let player = allPlayers[playerID] else { return }
		player.location = pulseUpdate.position
		player.trajectory = pulseUpdate.trajectory
		_ = player.save(on: request)
	}

	func updatePlayerPosition(playerID: String, pulseUpdate: PositionUpdate?, request: Request) {
		guard let pulseUpdate = pulseUpdate else { return }
		guard let player = allPlayers[playerID] else { return }
		player.location = pulseUpdate.position
		player.trajectory = pulseUpdate.trajectory

		_ = player.save(on: request).always { [weak self] in
			guard let room = self?.rooms[player.roomID] else { return }
			self?.sendMessageToAllPlayersOfRoom(room: room, message: WSMessage(messageType: .positionUpdate, payload: pulseUpdate.setting(playerID: playerID)))
		}
	}

	func playerChatted(message: ChatMessage?) {
		guard let message = message, let player = allPlayers[message.playerID] else { return }
		guard let room = rooms[player.roomID] else { return }
		print("\(player.username) (\(room.name)): \(message.message)")
		sendMessageToAllPlayersOfRoom(room: room, message: WSMessage(messageType: .chatMessage, payload: message))
	}

	func playerAttacked(with attackInfo: PlayerAttack?) {
		guard let attackInfo = attackInfo else { return }
		guard let player = allPlayers[attackInfo.attacker], let room = rooms[player.roomID] else { return }
		print(attackInfo)
		attackInfo.attackContacts.forEach {
			guard let victim = allPlayers[$0.victim] else { return }
			victim.updateCurrentHP(with: .adjust(by: Int(-10 * $0.strength)))
			print("\(victim.username) current HP: \(victim.currentHP)")
		}
		sendMessageToAllPlayersOfRoom(room: room, message: WSMessage(messageType: .playerAttack, payload: attackInfo))
	}

	// MARK: - Game logic
	private func gameLoop() {
		occupiedRooms.forEach {
			let players = $0.players
			let positionInfos: Set<PulseUpdate> = players.reduce(into: Set<PulseUpdate>(), {
				let position = PositionUpdate(position: $1.location, trajectory: $1.trajectory)
				let healthInfo = PlayerHealthUpdate(currentHP: $1.currentHP, maxHP: $1.maxHP)
				let pulseInfo = PulseUpdate(playerID: $1.playerID, positionUpdate: position, health: healthInfo)
				$0.insert(pulseInfo)
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
		return req.future(RoomCollection(rooms: rooms.mapValues { $0.representation }, roomCoordinates: Set(roomCoordinates.keys), spawnRoom: spawnRoom.id, seed: startingSeed))
	}

	func initializePlayer(_ req: Request) throws -> Future<UserResponse> {
		let user = try req.requireAuthenticated(User.self)

		let mid = Self.roomMid
		return try req.content.decode(PlayerInitRepresentation.self).flatMap { initRep -> Future<UserResponse> in
			let player = self.allPlayers[user.playerID] ?? user
			if initRep.respawn || player.roomID == -1 {
				player.location = CGPoint(x: mid, y: mid)
				player.updateCurrentHP(with: .set(to: player.maxHP))
				self.spawn(player: player, in: self.spawnRoom, from: nil)
			} else {
				self.spawn(player: player, in: self.rooms[player.roomID], from: nil)
				player.restoreInWorld()
			}
			player.avatar = initRep.playerAvatar
			return player.update(on: req).map { $0.userResponse }
		}
	}

	func moveToRoom(_ req: Request) throws -> Future<RoomChangeInfo> {
		let user = try req.requireAuthenticated(User.self)
		let player = allPlayers[user.playerID] ?? user

		return try req.content.decode(MoveRequest.self).flatMap { moveRequest -> Future<RoomChangeInfo> in
			let currentRoomID = player.roomID
			let newRoomID = moveRequest.roomID
			let currentRoom = self.rooms[currentRoomID] ?? self.spawnRoom
			guard let newRoom = self.rooms[newRoomID] else {
				throw HTTPError(identifier: "Invalid Room", reason: "Room doesn't exist")
			}
			print("\(player.username) moved from: \(currentRoom) newRoom: \(newRoom)")
			guard let fromDirection = newRoom.direction(of: currentRoom) else {
				throw HTTPError(identifier: "Direction not valid", reason: "perhaps room is not connected")
			}
			self.spawn(player: player, in: newRoom, from: fromDirection)
			return player.save(on: req).map { user -> RoomChangeInfo in
				return RoomChangeInfo(currentRoom: newRoom.id,
									  fromDirection: fromDirection,
									  spawnLocation: user.location,
									  otherPlayersInRoom: newRoom.players.map { $0.playerID })
			}
		}
	}

	func getRoomContents(_ req: Request) throws -> Future<RoomContents> {
		_ = try req.requireAuthenticated(User.self)

		return try req.content.decode(RoomContentRequest.self).flatMap { roomRequest -> Future<RoomContents> in

			guard let room = self.rooms[roomRequest.roomID] else {
				throw HTTPError(identifier: "Invalid Room", reason: "Room doesn't exist or player not in requested room")
			}

			return req.future(room.contents)
		}
	}
}
