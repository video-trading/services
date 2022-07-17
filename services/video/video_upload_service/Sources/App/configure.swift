import Fluent
import FluentMongoDriver
import Vapor
import SotoS3
import common
import env
import MQTTNIO
import client


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


public func configure(_ app: Application) throws {
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all, allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    app.middleware.use(cors, at: .beginning)
    
    try checkENV(app)
    try initializeDB(app)
    initializeAWS(app)
    try initializeMQTT(app)
    
    app.videoTranscoding.client = VideoTranscodingClient()
    
    // register routes
    try routes(app)
}
