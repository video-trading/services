//
//  File.swift
//
//
//  Created by Qiwei Li on 7/13/22.
//

import Foundation
import Vapor
import SotoS3
import MQTTNIO

//MARK: Application.AWS
public extension Application {
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
                    try $0.httpClient.syncShutdown()
                    try $0.syncShutdown()
                }
            }
        }
        
        let application: Application
    }
}

//MARK: Application.Mqtt
public extension Application {
    var mqtt: MQTT {
        .init(application: self)
    }
    
    struct MQTT {
        struct ClientKey: StorageKey {
            typealias Value = MQTTClient
        }
        
        public var client: MQTTClient {
            get {
                guard let client = self.application.storage[ClientKey.self] else {
                    fatalError("MQTTClient not setup. Use application.mqtt.client = ...")
                }
                return client
            }
            nonmutating set {
                self.application.storage.set(ClientKey.self, to: newValue){
                    try $0.disconnect().wait()
                    try $0.syncShutdownGracefully()
                }
            }
        }
        
        let application: Application
    }
}

//MARK: Application.AWS.S3
public extension Application.AWS {
    struct S3Key: StorageKey {
        public typealias Value = S3
    }
    
    var s3: S3 {
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

//MARK: Request.AWS
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

//MARK: Request.MQTT
public extension Request {
    var mqtt: MQTT {
        .init(request: self)
    }
        
    struct MQTT {
        var client: MQTTClient {
            return request.application.mqtt.client
        }
        
        let request: Request
    }
}
