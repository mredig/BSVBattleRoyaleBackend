import Vapor


/// Called after your application has initialized.
public func boot(_ app: Application, userController: UserController) throws {
	// your code here

	userController.app = app
}
