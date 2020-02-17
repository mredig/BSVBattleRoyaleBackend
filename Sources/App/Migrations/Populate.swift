//
//  Populate.swift
//  App
//
//  Created by Michael Redig on 2/16/20.
//

import FluentSQLite

/// sourced from https://mihaelamj.github.io/Pre-populating%20a%20Database%20with%20Data%20in%20Vapor/
final class PopulateUsers: Migration {
	typealias Database = SQLiteDatabase

	static let users = ["appreviewer", "ffff", "qqqq", "mredig"]

	static func prepare(on conn: SQLiteConnection) -> EventLoopFuture<Void> {
		let futures = users.compactMap { name in
			return User(username: name, password: "Aabc123!")?
				.create(on: conn)
				.map(to: Void.self) { _ in }
		}
		return Future<Void>.andAll(futures, eventLoop: conn.eventLoop)
	}

	static func revert(on conn: SQLiteConnection) -> EventLoopFuture<Void> {
//		do {
		let futures = users.map { name in
			return User.query(on: conn)
				.filter(\User.username == name)
				.delete()
		}
		return Future<Void>.andAll(futures, eventLoop: conn.eventLoop)
//		} catch {
//			return conn.eventLoop.newFailedFuture(error: error)
//		}
	}
}
