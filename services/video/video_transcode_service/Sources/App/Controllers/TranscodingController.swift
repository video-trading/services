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
struct TranscodingController: RouteCollection {
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
        return try await req.submitTranscodingRequest(id: id)
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
        return try await req.submitTranscodingResult(result: submittedTranscodingResult)
    }
    
    /**
     Get analyzing result and create a list of transcoding jobs
     */
    func submitAnalyzingResult(req: Request) async throws -> SubmitAnalyzingResultResponse {
        let analyzingResult = try req.content.decode(AnalyzingRequest.self)
        return try await req.submitAnalyzingResult(result: analyzingResult)
    }
    
}
