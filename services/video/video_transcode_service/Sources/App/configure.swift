import Fluent
import FluentMongoDriver
import Vapor
import common
import env

fileprivate func checkENV(_ app: Application) throws {
    let checker = EnvChecker(envs: [
        ENVIRONMENT_DB_KEY, ENVIRONMENT_S3_ENDPOINT,
        ENVIRONMENT_S3_REGION ,ENVIRONMENT_ACCESS_KEY,
        ENVIRONMENT_SECRET_KEY
    ])
    let checkResult = checker.check()
    
    if !checkResult.isNotMissing {
        app.logger.error("Missing keys: \(checkResult.missingKeys)")
        throw MissingKeyError.missingKey
    }
}


// configures your application
public func configure(_ app: Application) throws {
    let initializeHelper = InitializeHelper(app: app)
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all, allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    app.middleware.use(cors, at: .beginning)
    
    try checkENV(app)
    try initializeHelper.initializeDB()
    try initializeHelper.initializeMQTT()
    try initializeHelper.initializeAWS()
    try initializeHelper.initializeJWT()
    
    
    // register routes
    try routes(app)
}
