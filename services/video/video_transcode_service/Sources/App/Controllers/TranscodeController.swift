import Fluent
import Vapor
import common
import model

/**
 This controller contains two three functionalities
 1. Submit a transcoding request from upload video service, then it will send the video to the analyzer to analyze
 2. When analyzer send back the result (include video resolution), transcoding service will setup few transcoding jobs and add to queue
 3. After transcoding workers  send back the transcoding results, service will update transcoding status accordingly
 */
struct TranscodeController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post("video", "transcoding", ":id", use: submitTranscodeRequest)
        routes.post("video", "transcoding", "analyzing", use: submitAnalyzingResult)
        routes.post("video", "transcoding", "result" ,use: submitTranscodingResult)
        routes.get("video", "transcoding", "result", ":id", use: getTranscodingJobs)
    }
    /**
     Submit a transcoding request. This will also send video to the analyzing worker
     */
    func submitTranscodeRequest(req: Request) async throws -> AnalyzingJob {
        let id = try req.parameters.require("id", as: UUID.self)
        let video = try await VideoInfo.find(id, on: req.db)
        guard let video = video else {
            throw Abort(.notFound, reason: "Cannot find video with id: \(id)")
        }
        let downloadURL = try await getDownloadURL(req: req, video: video)
        let job = try await AnalyzingJob.fromVideo(req: req, videoSource: downloadURL, videoId: id.uuidString)
        let encodedData = try JSONEncoder().encode(job)
        
        video.status = .encoding
        try await video.update(on: req.db)
        
        try await req.mqtt.client.publish(to: Channels.analyzingWorker.rawValue, payload: .init(bytes: encodedData), qos: .atLeastOnce)
        return job
    }
    
    /**
     Get list of transcoding jobs by video id
     */
    func getTranscodingJobs(req: Request) async throws -> [TranscodingInfoModel] {
        let id = try req.parameters.require("id", as: UUID.self)
        let results = try await TranscodingInfoModel.query(on: req.db).filter(\.$videoId == id).all()
        return results
    }
    
    /**
     Submit transcoding result from worker
     */
    func submitTranscodingResult(req: Request) async throws -> TranscodingInfo  {
        let submittedTranscodingResult = try req.content.decode(TranscodingResult.self)
        let storedTranscodingJob = try await TranscodingInfoModel.find(submittedTranscodingResult.id, on: req.db)
        guard let storedTranscodingJob = storedTranscodingJob else {
            throw Abort(.badRequest, reason: "Cannot find stored transcoding job with the given id: \(submittedTranscodingResult.id)")
        }
        
        switch submittedTranscodingResult.status {
        case .uploaded:
            await onTranscodingSuccess(req: req, submittedData: submittedTranscodingResult, storedData: storedTranscodingJob)
        default:
            storedTranscodingJob.status = .failed
        }
        
        try await storedTranscodingJob.update(on: req.db)
        return storedTranscodingJob.toTranscodingInfo()
    }
    
    /**
     Get analyzing result and create a list of transcoding jobs
     */
    func submitAnalyzingResult(req: Request) async throws -> SubmitAnalyzingResultResponse {
        let analyzingResult = try req.content.decode(AnalyzingRequest.self)
        let video = try await VideoInfo.find(analyzingResult.videoId, on: req.db)
        guard let video = video else {
            throw Abort(.notFound, reason: "Cannot find video")
        }
        
        let endpoint = Environment.get(ENVIRONMENT_S3_ENDPOINT)!
        let bucket = Environment.get(ENVIRONMENT_S3_BUCKET_NAME)!
        try await findObject(req: req, bucket: bucket, key: analyzingResult.fileName)
        
        let originalVideoSource = try await getDownloadURL(req: req, video: video)
        
        video.cover = analyzingResult.cover
        video.length = analyzingResult.length
        video.quality = analyzingResult.quality
        try await video.update(on: req.db)
        
        // create a list of transcoding jobs
        let targetTranscodingJobs: [TranscodingJob] = try await analyzingResult.quality.getListTranscodingTargets().concurrentMap { res async throws in
            let uploadDestinationURLString: String = .transcodingURL(endpoint: endpoint, bucket: bucket, object: analyzingResult.fileName, resolution: res)
            let uploadFileName: String = .transcodingFileName(object: analyzingResult.fileName, resolution: res)
            
            guard let uploadDestination = URL(string: uploadDestinationURLString) else {
                throw Abort(.internalServerError, reason: "Cannot construct a url: \(uploadDestinationURLString)")
            }
            let signedURL = try await req.s3.signURL(url: uploadDestination, httpMethod: .PUT, expires: .hours(1))
            
            return TranscodingJob(videoId:analyzingResult.videoId, quality: res, bucketName: bucket, fileName: uploadFileName, source: signedURL.absoluteString, status: .pending, originalVideoSource: originalVideoSource)
        }
        
        for job in targetTranscodingJobs {
            let encoded = try JSONEncoder().encode(job)
            let transcodingInfoModel = job.toTranscodingInfoModel()
            try await transcodingInfoModel.create(on: req.db)
            try await req.mqtt.client.publish(to: Channels.transcodingWorker.rawValue, payload: .init(data: encoded), qos: .atLeastOnce)
        }
        
    
        
        return SubmitAnalyzingResultResponse(jobs: targetTranscodingJobs, createdAt: Date())
    }
    
}

extension TranscodeController {
    func getDownloadURL(req: Request, video: VideoInfo) async throws -> String{
        try await findObject(req: req, bucket: video.bucketName, key: video.fileName)
        
        guard let url = URL(string: video.source ?? "") else {
            throw Abort(.notFound, reason: "Cannot construct a valid url from video source: \(video.source ?? "nil")")
        }
        let signedURL = try await req.s3.signURL(url: url, httpMethod: .GET, expires: .hours(1))
        return signedURL.absoluteString
    }
    
    
    func onTranscodingSuccess(req: Request, submittedData: TranscodingResult, storedData: TranscodingInfoModel) async {
           // check if object exists
           do {
               let _ = try await req.s3.getObject(.init(bucket: submittedData.bucketName, key: submittedData.fileName))
               storedData.status = .success
           } catch {
               storedData.status = .failed
           }
       }
    
    
    
    func findObject(req: Request ,bucket: String, key: String) async throws {
        do {
            let _ = try await req.s3.getObject(.init(bucket: bucket, key: key))
        } catch {
            throw Abort(.notFound,  reason: "The given key \(key) not found")
        }
    }
    
}
