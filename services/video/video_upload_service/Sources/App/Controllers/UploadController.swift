import Fluent
import Vapor
import SotoS3
import model
import common


struct UploadController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post("video", "upload", use: upload)
        routes.patch("video", "status", ":id", use: updateStatus)
        routes.get("video", "status", ":id", use: getStatus)
        routes.delete("video", ":id", use: delete)
    }
    
    func delete(req: Request) async throws -> Response {
        let id = req.parameters.get("id")
        guard let id = id else {
            req.logger.error("Cannot find id in path parameter")
            throw Abort(.badRequest)
        }
        
        let uuid = UUID(uuidString: id)
        let previousInfo = try await VideoInfo.find(uuid, on: req.db)
        guard let previousInfo = previousInfo else {
            req.logger.error("Cannot find model with id: \(uuid?.uuidString ?? "No found") ")
            throw Abort(.notFound)
        }
        try await deleteFile(req: req, previous: previousInfo)
        try await previousInfo.delete(on: req.db)
        
        return Response(status: .ok)
    }
    
    func getStatus(req: Request) async throws -> VideoInfo {
        let id = req.parameters.get("id")
        guard let id = id else {
            req.logger.error("Cannot find id in path parameter")
            throw Abort(.badRequest)
        }
        
        let uuid = UUID(uuidString: id)
        let previousInfo = try await VideoInfo.find(uuid, on: req.db)
        guard let previousInfo = previousInfo else {
            req.logger.error("Cannot find model with id: \(uuid?.uuidString ?? "") ")
            throw Abort(.notFound)
        }
        return previousInfo
    }
    
    func updateStatus(req: Request) async throws -> Response {
        let id = req.parameters.get("id")
        let body = try req.content.decode(UpdateStatusRequest.self)
        
        guard let id = id else {
            req.logger.error("Cannot find id in path parameter")
            throw Abort(.badRequest)
        }
        
        let uuid = UUID(uuidString: id)
        let previousInfo = try await VideoInfo.find(uuid, on: req.db)
        guard let previousInfo = previousInfo else {
            req.logger.error("Cannot find model with id: \(uuid?.uuidString ?? "") ")
            throw Abort(.notFound)
        }
        
        switch body.status {
        case .success:
            await onUpdateStatusSuccess(req: req, previous: previousInfo)
        case .failed:
            await onUpdateStatusFailed(req: req, previous: previousInfo)
        case .canceled:
            await onUpdateStatusFailed(req: req, previous: previousInfo)
            
        }
        try await previousInfo.update(on: req.db)
        return Response(status: .accepted)
    }
    
    func upload(req: Request) async throws -> UploadResponse {
        var body = try req.content.decode(VideoInfoRequest.self)
        
        let s3URL = try URL.s3(object: body.fileName)
        body.fileName = s3URL.fileName
        
        let presignedURL = try await req.s3.signURL(url: s3URL.url, httpMethod: .PUT, expires: .hours(1))
        let videoInfo = body.toVideoInfo(presignedURL: s3URL.url)
        try await videoInfo.create(on: req.db)
        
        return UploadResponse(id: videoInfo.id!, preSignedURL: presignedURL.absoluteString)
    }
}

extension UploadController {
    func onUpdateStatusSuccess(req: Request, previous data: VideoInfo) async {
        // check if object exists
        do {
            let _ = try await req.s3.getObject(.init(bucket: Environment.get(ENVIRONMENT_S3_BUCKET_NAME)!, key: data.fileName))
            data.status = .uploaded
            data.statusDescription = "Video has been uploaded"
        } catch {
            req.logger.error("User submit a success status but cannot find object with name \(data.fileName)")
            data.status = .failed
            data.statusDescription = "Upload failed"
        }
    }
    
    func onUpdateStatusFailed(req: Request, previous data: VideoInfo) async {
        data.status = .failed
        data.statusDescription = "Failed to upload"
    }
    
    func onUpdateStatusCancelled(req: Request, previous data: VideoInfo) async {
        data.status = .canceled
        data.statusDescription = "User cancelled file upload"
    }
    
    func deleteFile(req: Request, previous data: VideoInfo) async throws {
        // check if object exists
        let _ = try await req.s3.deleteObject(.init(bucket: Environment.get(ENVIRONMENT_S3_BUCKET_NAME)!, key: data.fileName))
    }
}
