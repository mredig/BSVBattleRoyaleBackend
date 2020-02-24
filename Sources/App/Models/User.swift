import Authentication
import FluentSQLite
import Vapor

/// A registered user, capable of owning todo items.
final class User: SQLiteModel {
	// MARK: - DB / Account properties
	static let createdAtKey: TimestampKey? = \.createdAt
	static let updatedAtKey: TimestampKey? = \.updatedAt

	/// User's unique identifier.
	/// Can be `nil` if the user has not been saved yet.
	var id: Int?
	var username: String
	var password: String

	var createdAt: Date?
	var updatedAt: Date?

	// MARK: - Character Meta Properties
	lazy var webSocket: WebSocket? = nil
	var avatar = 0
	var playerID: String = UUID().uuidString
	var roomID = -1

	// MARK: - Character Live Properties
	static let startingHP = 100
	private(set) var currentHP = User.startingHP
	var maxHP = User.startingHP

	private var xLocation: Double = 0
	private var yLocation: Double = 0
	var location: CGPoint {
		get { CGPoint(x: xLocation, y: yLocation) }
		set {
			xLocation = Double(newValue.x)
			yLocation = Double(newValue.y)
		}
	}
	lazy var trajectory: CGVector = {
		.zero
	}()



	// MARK: - Lifecycle
	/// Creates a new `User`.
	init(id: Int? = nil, username: String, passwordHash: String) {
		self.id = id
		self.password = passwordHash
		self.username = username
		self.xLocation = 0
		self.yLocation = 0
	}

	convenience init?(id: Int? = nil, username: String, password: String) {
		guard let pwhash = try? BCrypt.hash(password) else { return nil }
		self.init(id: id, username: username, passwordHash: pwhash)
	}

	func updateCurrentHP(with change: HPChange) {
		let adjustedHP: Int
		switch change {
		case .adjust(by: let adjustment):
			adjustedHP = currentHP + adjustment
		case .set(to: let result):
			adjustedHP = result
		}

		currentHP = min(maxHP, max(0, adjustedHP))
	}

	func restoreInWorld() {
		// restore health based on how long the logout was
		guard let updatedAt = updatedAt else { return }
		let timeSinceLastUpdate = -updatedAt.timeIntervalSinceNow
		let minutesSince = timeSinceLastUpdate / 60
		let tenPercentMax = Double(maxHP) / 10

		let restoredHeath = Int(minutesSince * tenPercentMax)
		updateCurrentHP(with: .adjust(by: restoredHeath))
	}
}

extension User {
	enum CodingKeys: String, CodingKey  {
		case id
		case username
		case password
		case avatar
		case playerID
		case xLocation
		case yLocation
		case roomID
		case createdAt
		case updatedAt
		case currentHP
		case maxHP
	}
}


extension User: Hashable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
		hasher.combine(username)
	}

	static func == (lhs: User, rhs: User) -> Bool {
		rhs.username == lhs.username
	}
}

/// Allows users to be verified by basic / password auth middleware.
extension User: PasswordAuthenticatable {
	/// See `PasswordAuthenticatable`.
	static var usernameKey: WritableKeyPath<User, String> {
		return \.username
	}
	
	/// See `PasswordAuthenticatable`.
	static var passwordKey: WritableKeyPath<User, String> {
		return \.password
	}
}

/// Allows users to be verified by bearer / token auth middleware.
extension User: TokenAuthenticatable {
	/// See `TokenAuthenticatable`.
	typealias TokenType = UserToken
}

/// Allows `User` to be used as a Fluent migration.
extension User: Migration {
	/// See `Migration`.
	static func prepare(on conn: SQLiteConnection) -> Future<Void> {
		return SQLiteDatabase.create(User.self, on: conn) { builder in
			builder.field(for: \.id, isIdentifier: true)
			builder.field(for: \.username)
			builder.field(for: \.password)
			builder.field(for: \.roomID)
			builder.field(for: \.xLocation)
			builder.field(for: \.yLocation)
			builder.field(for: \.avatar)
			builder.field(for: \.updatedAt)
			builder.field(for: \.createdAt)
			builder.field(for: \.currentHP)
			builder.field(for: \.maxHP)
			builder.field(for: \.playerID)
			builder.unique(on: \.playerID)
			builder.unique(on: \.username)
		}
	}
}

/// Allows `User` to be encoded to and decoded from HTTP messages.
extension User: Content { }

/// Allows `User` to be used as a dynamic parameter in route definitions.
extension User: Parameter { }


enum HPChange {
	case set(to: Int)
	case adjust(by: Int)
}
