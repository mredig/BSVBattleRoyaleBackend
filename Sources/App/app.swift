import Vapor

/// Creates an instance of Application. This is called from main.swift in the run target.
public func app(_ env: Environment) throws -> Application {
	var config = Config.default()
	var env = env
	var services = Services.default()

	let connectionController = WSConnectionController()

	try configure(&config, &env, &services, connectionController: connectionController)
	let app = try Application(config: config, environment: env, services: services)
	try boot(app)
	return app
}
