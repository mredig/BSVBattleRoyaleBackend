import Crypto
import Vapor

/// Register your application's routes here.
public func routes(_ router: Router, userController: UserController, roomController: RoomController) throws {
	// public routes
	router.post("register", use: userController.create)

	// basic / password auth protected routes
	let basic = router.grouped(User.basicAuthMiddleware(using: BCryptDigest()))
	basic.post("login", use: userController.login)

	// bearer / token auth protected routes
	let bearer = router.grouped(User.tokenAuthMiddleware())
//	bearer.get("profile", use: userController.profile)

	bearer.post("initialize", use: roomController.initializePlayer)
	bearer.post("move", use: roomController.moveToRoom)
	bearer.post("playerinfo", use: userController.playerInfo)

	// example using another controller
//	let todoController = TodoController()
//	bearer.post("todos", use: todoController.create)
	router.get("overworld", use: roomController.getOverworld)
}
