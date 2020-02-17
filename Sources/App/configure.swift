import Authentication
import FluentSQLite
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config,
					  _ env: inout Environment,
					  _ services: inout Services,
					  connectionController: WSConnectionController,
					  userController: UserController,
					  roomController: RoomController) throws {

	// Register providers first
	try services.register(FluentSQLiteProvider())
	try services.register(AuthenticationProvider())

	// Register routes to the router
	let router = EngineRouter.default()
	let wss = NIOWebSocketServer.default()
	try routes(router, userController: userController, roomController: roomController)
	try connectionController.setupRoutes(wss, roomController: roomController)
	services.register(router, as: Router.self)
	services.register(wss, as: WebSocketServer.self)

	// Register middleware
	var middlewares = MiddlewareConfig() // Create _empty_ middleware config
	// middlewares.use(SessionsMiddleware.self) // Enables sessions.
	// middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
	middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
	services.register(middlewares)

	// Configure a SQLite database
	let sqlite = try SQLiteDatabase(storage: .memory)
//	let sqlite = try SQLiteDatabase(storage: .file(path: "temp.db"))

	// Register the configured SQLite database to the database config.
	var databases = DatabasesConfig()
//	databases.enableLogging(on: .sqlite)
	databases.add(database: sqlite, as: .sqlite)
	services.register(databases)

	/// Configure migrations
	var migrations = MigrationConfig()
	migrations.add(model: User.self, database: .sqlite)
	migrations.add(model: UserToken.self, database: .sqlite)

	// prepopulate user db
	migrations.add(migration: PopulateUsers.self, database: .sqlite)

	services.register(migrations)

}
