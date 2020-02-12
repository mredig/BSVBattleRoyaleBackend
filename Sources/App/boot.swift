import Vapor

var superRoomController: RoomController?

/// Called after your application has initialized.
public func boot(_ app: Application, userController: UserController) throws {
	// your code here

	userController.app = app
	let roomController = RoomController(roomLimit: 100, userController: userController)
	superRoomController = roomController
}
