import Foundation

struct Character: Codable, Identifiable {
    let characterId: Int
    let name: String
    let imageUrl: String
    let bio: String
    let isActive: Bool
    var problems: [Problem]?
    let createdAt: Date
    let updatedAt: Date
    
    var id: Int { characterId }
    
    enum CodingKeys: String, CodingKey {
        case characterId = "character_id"
        case name
        case imageUrl = "image_url"
        case bio
        case isActive = "is_active"
        case problems = "characterproblems"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Problem: Codable, Identifiable {
    let problemId: Int
    let name: String
    let iconUrl: String?
    let shortDescription: String
    let longDescription: String?
    let severityLevel: Int
    let tags: [String]?
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
    var id: Int { problemId }
    
    enum CodingKeys: String, CodingKey {
        case problemId = "problem_id"
        case name
        case iconUrl = "icon_url"
        case shortDescription = "short_description"
        case longDescription = "long_description"
        case severityLevel = "severity_level"
        case tags
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct CharacterProblem: Codable {
    let characterId: Int
    let problemId: Int
    let problem: Problem
    
    enum CodingKeys: String, CodingKey {
        case characterId = "character_id"
        case problemId = "problem_id"
        case problem = "problems"
    }
} 