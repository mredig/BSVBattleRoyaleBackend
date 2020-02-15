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
				let textToSend = "\(playerID): \(text)"
				print(peerInfo, textToSend)

				for (_, webSocketConnection) in self.connections {
					webSocketConnection.send(textToSend)
				}
			}

			webSocket.onClose.always {
				self.removeConnection(id: playerID)
				print("WEBSOCKET: Disconnected \(playerID) (\(peerInfo))")
			}

			webSocket.onCloseCode { closeCode in
				print("WEBSOCKET: Disconnected (\(playerID)) (\(peerInfo)) with code: \(closeCode)")
			}

			webSocket.onError { ws, error in
				print("WEBSOCKET: Error (\(peerInfo)):", ws, error)
			}

			webSocket.onBinary { ws, data in
				print("WEBSOCKET: Binary (\(peerInfo)): ", ws, data)
			}
		}
	}
}
