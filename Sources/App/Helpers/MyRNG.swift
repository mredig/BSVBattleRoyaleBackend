//
//  MyRNG.swift
//  App
//
//  Created by Michael Redig on 2/11/20.
//

import Foundation

class MyRNG {
	var seed: UInt64

	init(seed: UInt64 = UInt64(CFAbsoluteTimeGetCurrent() * 10000)) {
		self.seed = seed
	}

	func randomNumber(max: UInt64 = UInt64.max) -> UInt64 {
		let a: UInt64 = 16807
		let c: UInt64 = 0
		seed = (a * seed + c) % 2147483647
		return seed % max
	}

	func randomInt(max: Int = Int.max) -> Int {
		let value = randomNumber(max: UInt64(max))
		return Int(value)
	}

	func randomChoice<Element>(from array: [Element]) -> Element? {
		let maxValue = UInt64(array.count)
		guard maxValue > 0 else { return nil }
		return array[Int(randomNumber(max: maxValue))]
	}
}


#if os(Linux)
func CFAbsoluteTimeGetCurrent() -> TimeInterval {
	Date().timeIntervalSinceReferenceDate
}
#endif
