@testable import App
@testable import common
@testable import model
import XCTVapor

final class AppTests: XCTestCase {
    let payload = JWTVerificationPayload(subject: .init(value: "Hello"), expiration: .init(value: .now.addingTimeInterval(10)), userId: "0xabcde")
    
    override func setUp() async throws {
        setenv(ENVIRONMENT_DB_KEY, "mongodb://user:password@localhost:27017/video", 1)
        setenv(ENVIRONMENT_ACCESS_KEY, "test", 1)
        setenv(ENVIRONMENT_SECRET_KEY, "test", 1)
        setenv(ENVIRONMENT_PASSWORD, "password", 1)
    }
    
    func testUser() async throws {
        let app = Application(.testing)
        defer {
            app.shutdown()
        }
        try configure(app)
        let token = try app.jwt.signers.sign(payload)
        var userId: String = ""
        
        try app.test(.POST, "https://orca-app-pcq33.ondigitalocean.app/create", beforeRequest: { req in
            try req.content.encode(VideoInfoRequest(name: "abc", gender: "male", age: 10, userId: "0xasdf", id: []))
            req.headers.bearerAuthorization = BearerAuthorization(token: token)
            
        }, afterResponse: { res in
            let data = try res.content.decode(UserResponse.self)
            XCTAssertEqual(res.status, .ok)
            XCTAssertGreaterThan(data.id.uuidString.count, 1)
            userId = data.id.uuidString
        })
        
        try app.test(.GET, "https://orca-app-pcq33.ondigitalocean.app/(userId)", beforeRequest: { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: token)
        }) { statusResult in
            let status = try statusResult.content.decode(UserInfo.self)
            XCTAssertEqual(status.status, .pending)
        }
        
    }
}
