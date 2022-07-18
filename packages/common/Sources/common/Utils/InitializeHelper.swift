import Vapor
import Fluent
import SotoS3
import FluentMongoDriver
import MQTTNIO
import JWT


public class InitializeHelper {
    let app: Application
    
    public init(app: Application) {
        self.app = app
    }
    
    // configures your application
    public func initializeDB() throws {
        try app.databases.use(.mongo(
            connectionString: Environment.get(ENVIRONMENT_DB_KEY)!
        ), as: .mongo)
    }
    
    public func initializeAWS() throws {
        let accessKey = Environment.get(ENVIRONMENT_ACCESS_KEY)!
        let secretKey = Environment.get(ENVIRONMENT_SECRET_KEY)!
        let endpoint = Environment.get(ENVIRONMENT_S3_ENDPOINT)!
        let region = Environment.get(ENVIRONMENT_S3_REGION)!

        var configuration = HTTPClient.Configuration()
        configuration.httpVersion = .http1Only

        app.aws.client = AWSClient(
            credentialProvider: .static(accessKeyId: accessKey, secretAccessKey: secretKey),
            httpClientProvider: .shared(HTTPClient(
                eventLoopGroupProvider: .createNew,
                configuration: configuration
            ))
        )
        app.aws.s3 = S3(client: app.aws.client, region: .other(region), endpoint: endpoint)
    }
    
    public func initializeMQTT() throws {
        let client = MQTTClient(
            host: "localhost",
            port: 1883,
            identifier: "Client",
            eventLoopGroupProvider: .createNew,
            configuration: .init(userName: "user", password: "password")
        )
        _ = try client.connect().wait()
        app.mqtt.client = client
    }

    public func initializeJWT() throws {
        app.jwt.signers.use(.hs256(key: Environment.get(ENVIRONMENT_PASSWORD)!))
    }
    
}






