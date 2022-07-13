//
//  File.swift
//  
//
//  Created by Qiwei Li on 7/13/22.
//

import Foundation
import Vapor
import SotoS3

extension Application {
    var aws: AWS {
           .init(application: self)
       }

       struct AWS {
           struct ClientKey: StorageKey {
               typealias Value = AWSClient
           }

           public var client: AWSClient {
               get {
                   guard let client = self.application.storage[ClientKey.self] else {
                       fatalError("AWSClient not setup. Use application.aws.client = ...")
                   }
                   return client
               }
               nonmutating set {
                   self.application.storage.set(ClientKey.self, to: newValue) {
                       try $0.syncShutdown()
                   }
               }
           }

           let application: Application
       }
}

extension Application.AWS {
    struct S3Key: StorageKey {
        typealias Value = S3
    }

    public var s3: S3 {
        get {
            guard let s3 = self.application.storage[S3Key.self] else {
                fatalError("S3 not setup. Use application.aws.s3 = ...")
            }
            return s3
        }
        nonmutating set {
            self.application.storage[S3Key.self] = newValue
        }
    }
}


public extension Request {
    var aws: AWS {
        .init(request: self)
    }
    
    var s3: S3 {
        return aws.request.application.aws.s3
    }

    struct AWS {
        var client: AWSClient {
            return request.application.aws.client
        }

        let request: Request
    }
}
