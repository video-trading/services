//
//  File.swift
//  
//
//  Created by Qiwei Li on 7/14/22.
//

import Foundation
import Vapor
import common
import Alamofire


public class VideoTranscodingClient: Client, VideoTranscodingProtocol {

    
    override public init() {
        super.init()
        self.requiredEnvironmentKeys = [ENVIRONMENT_TRANSCODING_URL]
    }
    
    public func submitTranscodingRequest(id: UUID) async throws -> AnalyzingJob {
        let transcodingURL = Environment.get(ENVIRONMENT_TRANSCODING_URL)!
        guard var url = URL(string: transcodingURL) else {
            throw Abort(.badRequest, reason: "Given transcoding url is invalid: \(transcodingURL)")
        }
        url.appendPathComponent("video/transcoding/\(id.uuidString)")
        let task = AF.request(url, method: .post).serializingDecodable(AnalyzingJob.self)
        let value = try await task.value
        return value
    }
}

public extension Application {
    var videoTranscoding: VideoClient {
        .init(application: self)
    }
    
    struct VideoClient {
        struct ClientKey: StorageKey {
            typealias Value = VideoTranscodingClient
        }
        
        public var client: VideoTranscodingClient {
            get {
                guard let client = self.application.storage[ClientKey.self] else {
                    fatalError("VideoTranscoding not setup. Use application.videoTranscoding.client = ...")
                }
                return client
            }
            nonmutating set {
                self.application.storage.set(ClientKey.self, to: newValue) {
                    try $0.initialize()
                }
            }
        }
        
        let application: Application
    }
}


public extension Vapor.Request {
    var videoTranscoding: VideoClient {
        .init(request: self)
    }
    
    struct VideoClient {
        public var client: VideoTranscodingClient {
            return request.application.videoTranscoding.client
        }
        
        let request: Vapor.Request
    }
}

