//
//  File.swift
//  
//
//  Created by Qiwei Li on 7/18/22.
//

import Foundation
import JWT

public struct JWTVerificationPayload: JWTPayload {
    // Maps the longer Swift property names to the
    // shortened keys used in the JWT payload.
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case userId = "userId"
    }
    
    // The "sub" (subject) claim identifies the principal that is the
    // subject of the JWT.
    var subject: SubjectClaim
    
    var expiration: ExpirationClaim
    
    // UserId
    var userId: String
    
    public func verify(using signer: JWTSigner) throws {
        try self.expiration.verifyNotExpired()
    }
}
