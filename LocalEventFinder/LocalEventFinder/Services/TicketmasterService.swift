//
//  TicketmasterService.swift
//  LocalEventFinder
//
//  Created by Nam Nguyen on 12/2/24.
//
import Foundation

enum TicketmasterError: LocalizedError {
    case invalidURL
    case networkError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration"
        case .networkError:
            return "Failed to fetch events from server"
        case .decodingError:
            return "Failed to process server response"
        }
    }
}

class TicketmasterService {
    static let shared = TicketmasterService()
    private let baseURL = "https://app.ticketmaster.com/discovery/v2/events.json"
    
    private init() {}
    
    func fetchEvents(latitude: Double, longitude: Double, radius: Int = 10, page: Int = 0) async throws -> (events: [Event], hasMore: Bool) {
        print("Starting Ticketmaster API request with coordinates: \(latitude), \(longitude)")
            
        var components = URLComponents(string: baseURL)!
        
        // Get current date and date 30 days from now
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        
        let startDateTime = dateFormatter.string(from: Date())
        let endDateTime = dateFormatter.string(from: Calendar.current.date(byAdding: .day, value: 30, to: Date())!)
            
        components.queryItems = [
            URLQueryItem(name: "apikey", value: Config.ticketmasterApiKey),
            URLQueryItem(name: "latlong", value: "\(latitude),\(longitude)"),
            URLQueryItem(name: "radius", value: "\(radius)"),
            URLQueryItem(name: "unit", value: "miles"),
            URLQueryItem(name: "size", value: "20"),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "startDateTime", value: startDateTime),
            URLQueryItem(name: "endDateTime", value: endDateTime),
            URLQueryItem(name: "classificationName", value: "music,sports,arts"),
            URLQueryItem(name: "sort", value: "date,asc")
        ]
        
        guard let url = components.url else {
            print("Failed to construct URL")
            throw TicketmasterError.invalidURL
        }
        
        print("Making request to URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid response type")
            throw TicketmasterError.networkError
        }
        
        print("Response status code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("Error status code: \(httpResponse.statusCode)")
            throw TicketmasterError.networkError
        }
        
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(TicketmasterResponse.self, from: data)
            print("Received \(response.embedded?.events.count ?? 0) events")
            
            let mappedEvents: [Event] = (response.embedded?.events ?? []).map { tmEvent in
                let venue = tmEvent.embedded?.venues?.first
                let classification = tmEvent.classifications?.first
                
                print("Mapping event: \(tmEvent.name) - Type: \(classification?.segment?.name ?? "Unknown")")
                
                return Event(
                    id: tmEvent.id,
                    name: Event.EventName(
                        text: tmEvent.name,
                        html: tmEvent.name
                    ),
                    description: Event.EventDescription(
                        text: tmEvent.info ?? "Event at \(venue?.name ?? "Unknown Venue")",
                        html: tmEvent.info ?? "Event at \(venue?.name ?? "Unknown Venue")"
                    ),
                    start: Event.EventDate(
                        timezone: tmEvent.dates.start.timezone ?? "UTC",
                        local: "\(tmEvent.dates.start.localDate ?? "")T\(tmEvent.dates.start.localTime ?? "00:00:00")",
                        utc: tmEvent.dates.start.dateTime ?? ""
                    ),
                    end: Event.EventDate(
                        timezone: tmEvent.dates.start.timezone ?? "UTC",
                        local: "\(tmEvent.dates.start.localDate ?? "")T\(tmEvent.dates.start.localTime ?? "00:00:00")",
                        utc: tmEvent.dates.start.dateTime ?? ""
                    ),
                    venue: Event.Venue(
                        id: venue?.id ?? "",
                        name: venue?.name ?? "Unknown Venue",
                        address: Event.Venue.Address(
                            address_1: venue?.address?.line1,
                            address_2: nil,
                            city: venue?.city?.name,
                            region: venue?.state?.stateCode,
                            postal_code: venue?.postalCode,
                            country: venue?.country?.countryCode,
                            localized_address_display: [
                                venue?.address?.line1,
                                venue?.city?.name,
                                venue?.state?.stateCode
                            ].compactMap { $0 }.joined(separator: ", ")
                        ),
                        latitude: venue?.location?.latitude,
                        longitude: venue?.location?.longitude
                    ),
                    classifications: [
                        Event.Classification(
                            segment: Event.Classification.Segment(
                                name: classification?.segment?.name
                            ),
                            genre: Event.Classification.Genre(
                                name: classification?.genre?.name
                            ),
                            subGenre: Event.Classification.SubGenre(
                                name: classification?.subGenre?.name
                            )
                        )
                    ]
                )
            }
            
            let hasMore = (response.page?.number ?? 0) < (response.page?.totalPages ?? 1) - 1
            return (events: mappedEvents, hasMore: hasMore)
            
        } catch {
            print("Decoding error: \(error)")
            throw TicketmasterError.decodingError
        }
    }
}

// Response Models
struct TicketmasterResponse: Codable {
    let embedded: EmbeddedEvents?
    let page: Page?
    
    enum CodingKeys: String, CodingKey {
        case embedded = "_embedded"
        case page
    }
}

struct Page: Codable {
    let size: Int
    let totalElements: Int
    let totalPages: Int
    let number: Int
}

struct EmbeddedEvents: Codable {
    let events: [TicketmasterEvent]
}

struct TicketmasterEvent: Codable {
    let id: String
    let name: String
    let info: String?
    let dates: Dates
    let embedded: VenueEmbedded?
    let classifications: [Classification]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, info, dates, classifications
        case embedded = "_embedded"
    }
}

struct Classification: Codable {
    let segment: Segment?
    let genre: Genre?
    let subGenre: SubGenre?
}

struct Segment: Codable {
    let name: String?
}

struct Genre: Codable {
    let name: String?
}

struct SubGenre: Codable {
    let name: String?
}

struct Dates: Codable {
    let start: Start
}

struct Start: Codable {
    let localDate: String?
    let localTime: String?
    let dateTime: String?
    let timezone: String?
}

struct VenueEmbedded: Codable {
    let venues: [Venue]?
}

struct Venue: Codable {
    let id: String?
    let name: String
    let address: Address?
    let city: City?
    let state: State?
    let country: Country?
    let location: Location?
    let postalCode: String?
    
    struct Address: Codable {
        let line1: String?
    }
    
    struct City: Codable {
        let name: String?
    }
    
    struct State: Codable {
        let name: String?
        let stateCode: String?
    }
    
    struct Country: Codable {
        let name: String?
        let countryCode: String?
    }
    
    struct Location: Codable {
        let latitude: String?
        let longitude: String?
    }
}
