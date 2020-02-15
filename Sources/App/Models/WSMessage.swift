//
//  WSMessage.swift
//  App
//
//  Created by Michael Redig on 2/15/20.
//

import Foundation

enum WSMessageType: String, Codable {
	case positionUpdate
	case positionPulse
	case chatMessage
	case playerAttack
}

enum WSMessageError: Error {
	case cantEncodeMagicString
	case cantDecodeMagicString(bytes: [UInt8])
}

struct WSMessage<Payload: Codable> {
	let messageType: WSMessageType
	let payload: Payload

	func encode() throws -> Data {
		guard var magic = messageType.rawValue.data(using: .utf8) else {
			throw WSMessageError.cantEncodeMagicString
		}
		//null terminate
		magic.append(0)

		let plist = try PropertyListEncoder().encode(payload)
		magic.append(plist)

		return magic
	}
}

extension Data {
	func getMagic() -> WSMessageType? {
		var magic = Data()
		for value in self {
			guard value != 0 else { break }
			magic.append(value)
		}
		guard let stringValue = String(data: magic, encoding: .utf8) else { return nil }
		return WSMessageType(rawValue: stringValue)
	}

	func extractPayload<Payload: Codable>(payloadType: Payload.Type) throws -> Payload {
		guard let magic = self.getMagic() else {
			let high = Swift.min(self.count, 20)
			throw WSMessageError.cantDecodeMagicString(bytes: Array(self[0..<high]))
		}
		let embeddedData = self.subdata(in: (magic.rawValue.count + 1)..<self.count)
		return try PropertyListDecoder().decode(payloadType, from: embeddedData)
	}
}
