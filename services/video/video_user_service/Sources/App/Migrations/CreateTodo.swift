import Fluent



    func revert(on database: Database) async throws {
        try await database.schema("todos").delete()
    }

