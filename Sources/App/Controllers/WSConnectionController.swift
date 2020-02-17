//
//  ConnectionController.swift
//  App
//
//  Created by Michael Redig on 2/10/20.
//

import Foundation
import Vapor

public class WSConnectionController {
	private var connections = [String: WebSocket]()

	public func addConnection(connection: WebSocket, id: String) {
		connections[id]?.close(code: .policyViolation)
		connections[id] = connection
	}

	public func removeConnection(id: String) {
		connections[id]?.close()
		connections[id] = nil
	}

	subscript(_ id: String) -> WebSocket? {
		connections[id]
	}

}

extension WSConnectionController {
	func setupRoutes(_ router: NIOWebSocketServer, roomController: RoomController) throws {
		// setup echoing
		router.get("ws/rooms", String.parameter) { webSocket, request in
			let playerID = try request.parameters.next(String.self)
			let peerInfo = request.http.remotePeer.description

			guard let player = roomController.allPlayers[playerID] else { return }
			player.webSocket = webSocket

			self.addConnection(connection: webSocket, id: playerID)
			print("WEBSOCKET: connected \(playerID) (\(peerInfo))")

			webSocket.onText { ws, text in
				print("WEBSOCKET: text \(peerInfo) (\(text))")
			}

			webSocket.onClose.always {
				self.removeConnection(id: playerID)
				print("WEBSOCKET: Disconnected \(playerID) (\(peerInfo))")
				roomController.playerDisconnected(id: playerID)
			}

			webSocket.onCloseCode { closeCode in
				print("WEBSOCKET: Disconnected (\(playerID)) (\(peerInfo)) with code: \(closeCode)")
				roomController.playerDisconnected(id: playerID)
			}

			webSocket.onError { ws, error in
				print("WEBSOCKET: Error (\(peerInfo)):", ws, error)
			}

			webSocket.onBinary { [weak self] ws, data in
//				print("WEBSOCKET: Binary (\(peerInfo)): ", ws, data)
				if let magic = data.getMagic() {
					switch magic {
					case .positionPulse:
						roomController.updatePlayerPulse(playerID: playerID, pulseUpdate: self?.decodeSafely(type: PositionPulseUpdate.self, from: data), request: request)
					case .chatMessage:
						roomController.playerChatted(message: self?.decodeSafely(type: ChatMessage.self, from: data))
					case .playerAttack:
						roomController.playerAttacked(with: self?.decodeSafely(type: PlayerAttack.self, from: data))
					case .positionUpdate:
						roomController.updatePlayerPosition(playerID: playerID, pulseUpdate: self?.decodeSafely(type: PositionPulseUpdate.self, from: data), request: request)
					case .latencyPing:
						ws.send(data)
					}
				} else {
					print("got data: \(data)")
				}
			}
		}
	}

	private func decodeSafely<T: Codable>(type: T.Type, from data: Data) -> T? {
		do {
			return try data.extractPayload(payloadType: T.self)
		} catch {
			NSLog("Error extracting payload (\(type)) from data: \(error)")
		}
		return nil
	}
}
