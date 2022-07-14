import env
protocol ClientProtocol {
    var name: String { get }
    var requiredEnvironmentKeys: [String] { get }
    func initialize() throws -> Void
}

class Client: ClientProtocol {
    var name: String = ""

    var requiredEnvironmentKeys: [String] = []

    public init() {}

    func initialize() throws {
        let result = EnvChecker(envs: requiredEnvironmentKeys).check()
        if !result.isNotMissing {
            fatalError("Missing required keys: \(result.missingKeys)")
        }
    }
}
