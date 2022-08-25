import Fluent
import Vapor
import Foundation

struct userController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post("create",use:post)
        routes.get(":id",use:get_user)
    }
    
    
    func post(request:Request)async throws -> User{
        let userData = try request.content.decode(User.self)
        try await userData.create(on:request.db)
        return userData
    }
    func get_user(request:Request)async throws ->User{
        let id = request.parameter.require("Id")
        
        guard let id = id else{
            throw Abort(.badRequest)
        }
        let user = try await User.find(id, on:request.db)
        
        guard let user = user else{
            throw Abort(.notFound)
        }
        return user
    }

}
