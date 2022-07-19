import Fluent
import Vapor

enum Gender: String,Codable{
    case male
    case female
    case undertermined
}

final class User: Model, Content {
    static let schema = "todos"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String
    
    @Field(key: "user_id")
    var userId: String
    
    @Field(key: "age")
    var age: Int
    
    @Field(key: "gender")
    var gender: Gender

    init() { }

    init(id: UUID? = nil, name: String, userId:String, age:Int, gender:Gender) {
        self.id = id
        self.name = name
        self.name = name
        self.age = age
        self.gender = gender
    }
}
