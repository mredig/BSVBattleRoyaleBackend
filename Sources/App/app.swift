import Vapor

/// Creates an instance of Application. This is called from main.swift in the run target.
public func app(_ env: Environment) throws -> Application {
	var config = Config.default()
	var env = env
	var services = Services.default()

	let connectionController = WSConnectionController()
	let userController = UserController()
	let roomController = RoomController(roomLimit: 100, userController: userController)
//	roomController.generateRooms()

	try configure(&config, &env, &services, connectionController: connectionController, userController: userController, roomController: roomController)
	let app = try Application(config: config, environment: env, services: services)
	try boot(app, userController: userController)
	return app
}
