import Fluent
import FluentMongoDriver
import Vapor
import common
import env



fileprivate func checkENV(_ app: Application) throws {
    let checker = EnvChecker(envs: [
        ENVIRONMENT_DB_KEY, ENVIRONMENT_ACCESS_KEY,
        ENVIRONMENT_SECRET_KEY, ENVIRONMENT_PASSWORD,
    ])
    let checkResult = checker.check()
    
    if !checkResult.isNotMissing {
        app.logger.error("Missing keys: \(checkResult.missingKeys)")
        throw MissingKeyError.missingKey
    }
}


public func configure(_ app: Application) throws {
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all, allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    app.middleware.use(cors, at: .beginning)
    app.middleware.use(JWTMiddleWare())
    
    
    let initializeHelper = InitializeHelper(app: app)
    
    try checkENV(app)
    try initializeHelper.initializeDB()
    try initializeHelper.initializeJWT()

    
    // register routes
    try routes(app)
}
