import Fluent
import FluentMongoDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    try app.databases.use(.mongo(connectionString: Environment.get("DATABASE_URL")!
    ), as: .mongo)


    // register routes
    try routes(app)
}
