import Fluent
import FluentMongoDriver
import Vapor
import SotoS3
import common
import env

// configures your application
public func configure(_ app: Application) throws {
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all, allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    app.middleware.use(cors, at: .beginning)
    
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
    
    try app.databases.use(.mongo(
        connectionString: Environment.get("DATABASE_URL")!
    ), as: .mongo)

    
    let accessKey = Environment.get(ENVIRONMENT_ACCESS_KEY)!
    let secretKey = Environment.get(ENVIRONMENT_SECRET_KEY)!
    let endpoint = "https://\(Environment.get(ENVIRONMENT_S3_ENDPOINT)!)"
    let region = Environment.get(ENVIRONMENT_S3_REGION)!
    
    var configuration = HTTPClient.Configuration()
    configuration.httpVersion = .http1Only
    
    app.aws.client = AWSClient(
        credentialProvider: .static(accessKeyId: accessKey, secretAccessKey: secretKey),
        httpClientProvider: .shared( HTTPClient(
            eventLoopGroupProvider: .createNew,
            configuration: configuration
        ))
    )
    

    
    app.aws.s3 = S3(client: app.aws.client, region: .other(region), endpoint: endpoint)
    
    app.migrations.add(CreateTodo())
    
    // register routes
    try routes(app)
}
