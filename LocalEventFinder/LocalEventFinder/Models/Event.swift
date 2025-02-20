//
//  Event.swift
//  LocalEventFinder
//
//  Created by Nam Nguyen on 11/26/24.
//
import Foundation

struct Event: Identifiable, Codable, Hashable {
    let id: String
    let name: EventName
    let description: EventDescription
    let start: EventDate
    let end: EventDate
    let venue: Venue
    let classifications: [Classification]?  // Added
    var isFavorite: Bool = false
    
    struct EventName: Codable, Hashable {
        let text: String
        let html: String
    }
    
    struct EventDescription: Codable, Hashable {
        let text: String
        let html: String
    }
    
    struct EventDate: Codable, Hashable {
        let timezone: String
        let local: String
        let utc: String
    }
    
    struct Venue: Codable, Hashable {
        let id: String
        let name: String
        let address: Address
        let latitude: String?
        let longitude: String?
        
        struct Address: Codable, Hashable {
            let address_1: String?
            let address_2: String?
            let city: String?
            let region: String?
            let postal_code: String?
            let country: String?
            let localized_address_display: String?
        }
    }
    
    struct Classification: Codable, Hashable {  // Added
        let segment: Segment?
        let genre: Genre?
        let subGenre: SubGenre?
        
        struct Segment: Codable, Hashable {
            let name: String?
        }
        
        struct Genre: Codable, Hashable {
            let name: String?
        }
        
        struct SubGenre: Codable, Hashable {
            let name: String?
        }
    }
    
    var displayName: String {
        name.text
    }
    
    var displayDescription: String {
        description.text
    }
    
    var displayAddress: String {
        venue.address.localized_address_display ?? "No address available"
    }
    
    // Added computed properties for event type information
    var eventType: String {
        classifications?.first?.segment?.name ?? "Other"
    }
    
    var genre: String {
        classifications?.first?.genre?.name ?? "Unknown Genre"
    }
    
    var subGenre: String {
        classifications?.first?.subGenre?.name ?? "Unknown Subgenre"
    }
    
    // Helper method to check event type
    func isEventType(_ type: String) -> Bool {
        return eventType.lowercased() == type.lowercased()
    }
    
    // Helper method to check if event matches any of the given types
    func matchesEventTypes(_ types: [String]) -> Bool {
        guard let eventType = classifications?.first?.segment?.name?.lowercased() else {
            return false
        }
        return types.contains { $0.lowercased() == eventType }
    }
}

// Extension to help with filtering events
extension Array where Element == Event {
    func filterByEventTypes(_ types: [String]) -> [Event] {
        self.filter { event in
            event.matchesEventTypes(types)
        }
    }
    
    var musicEvents: [Event] {
        self.filter { $0.isEventType("Music") }
    }
    
    var sportsEvents: [Event] {
        self.filter { $0.isEventType("Sports") }
    }
    
    var artsEvents: [Event] {
        self.filter { $0.isEventType("Arts & Theatre") }
    }
}
