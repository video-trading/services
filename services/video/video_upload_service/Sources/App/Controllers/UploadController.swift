import Fluent
import Vapor
import SotoS3
import model
import common


struct UploadController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post("video", "upload", use: upload)
        routes.get("video", "download", ":id", use: download)
        routes.patch("video", "status", ":id", use: updateStatus)
        routes.get("video", "status", ":id", use: getStatus)
        routes.delete("video", ":id", use: delete)
    }
    
    func delete(req: Request) async throws -> Response {
        
        let previousInfo = try await findPreviousInfoById(req: req)
        return try await req.delete(video: previousInfo)
    }
    
    func getStatus(req: Request) async throws -> VideoInfo {
        let previousInfo = try await findPreviousInfoById(req: req)
        return previousInfo
    }
    
    func updateStatus(req: Request) async throws -> Response {
        let previousInfo = try await findPreviousInfoById(req: req)
        let body = try req.content.decode(UpdateStatusRequest.self)
        return try await req.updateStatus(video: previousInfo, status: body)
    }
    
    func upload(req: Request) async throws -> UploadResponse {
        var body = try req.content.decode(VideoInfoRequest.self)
        return try await req.upload(video: &body)
    }
    
    func download(req: Request) async throws -> DownloadResponse {
       let previousInfo = try await findPreviousInfoById(req: req)
       return try await req.download(video: previousInfo)
    }
    
    
    func findPreviousInfoById(req: Request) async throws -> VideoInfo {
        let id = try req.parameters.require("id", as: UUID.self)
        let previousInfo = try await VideoInfo.find(id, on: req.db)
        guard let previousInfo = previousInfo else {
            req.logger.error("Cannot find model with id: \(id.uuidString) ")
            throw Abort(.notFound)
        }
        return previousInfo
    }
}
