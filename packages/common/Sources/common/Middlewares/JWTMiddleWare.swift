//
//  File.swift
//  
//
//  Created by Qiwei Li on 7/18/22.
//

import Foundation
import Vapor
import JWT
import JWTKit


public class JWTMiddleWare: AsyncMiddleware {
    public init(){
        
    }
    
    public func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let token = request.headers.bearerAuthorization else {
            throw Abort(.unauthorized, reason: "No access token found in header")
        }
        do {
            try request.jwt.verify(token.token, as: JWTVerificationPayload.self)

        } catch let error as JWTError {
            throw Abort(.unauthorized, reason: error.reason)
        }
        return try await next.respond(to: request)
    }
}
