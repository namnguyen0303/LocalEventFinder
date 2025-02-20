//
//  User.swift
//  LocalEventFinder
//
//  Created by Nam Nguyen on 11/26/24.
//

struct User: Codable {
    let id: String
    let email: String
    var favorites: [String]
    
    enum CodingKeys: String, CodingKey {
        case id = "uid"
        case email
        case favorites
    }
}
