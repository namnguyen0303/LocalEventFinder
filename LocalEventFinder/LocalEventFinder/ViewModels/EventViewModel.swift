//
//  EventViewModel.swift
//  LocalEventFinder
//
//  Created by Nam Nguyen on 11/26/24.
//

import Foundation
import CoreLocation

@MainActor
class EventViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var searchRadius: Int = 10
    @Published var error: Error?
    @Published var hasMoreEvents = false
    
    private let locationService: LocationService
    private let favoritesManager: FavoritesManager
    private var currentPage = 0
    private var isFetchingMore = false
    
    init(locationService: LocationService, favoritesManager: FavoritesManager) {
        self.locationService = locationService
        self.favoritesManager = favoritesManager
    }
    
    func fetchNearbyEvents(loadMore: Bool = false) async {
        guard let location = locationService.location else {
            print("No location available")
            return
        }
        
        if !loadMore {
            currentPage = 0
            isLoading = true
            error = nil
        } else if isFetchingMore {
            return
        }
        
        isFetchingMore = loadMore
        
        do {
            print("Fetching events for location: \(location.coordinate.latitude), \(location.coordinate.longitude), radius: \(searchRadius)km, page: \(currentPage)")
            
            let result = try await TicketmasterService.shared.fetchEvents(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                radius: searchRadius,
                page: currentPage
            )
            
            // Update events with favorite status
            let updatedEvents = favoritesManager.updateEventsWithFavoriteStatus(result.events)
            
            if loadMore {
                self.events.append(contentsOf: updatedEvents)
            } else {
                self.events = updatedEvents
            }
            
            self.hasMoreEvents = result.hasMore
            self.currentPage += 1
            
            print("Fetched \(result.events.count) events. Has more: \(result.hasMore)")
            
        } catch {
            print("Error fetching events: \(error.localizedDescription)")
            self.error = error
            if !loadMore {
                self.events = []
            }
        }
        
        isLoading = false
        isFetchingMore = false
    }
    
    func refreshEvents() async {
        await fetchNearbyEvents(loadMore: false)
    }
    
    func loadMoreEventsIfNeeded(currentEvent event: Event) async {
        let thresholdIndex = events.index(events.endIndex, offsetBy: -5)
        if events.firstIndex(where: { $0.id == event.id }) ?? 0 >= thresholdIndex,
           hasMoreEvents && !isLoading && !isFetchingMore {
            await fetchNearbyEvents(loadMore: true)
        }
    }
    
    // Helper method to format coordinates for display
    func formatCoordinate(_ coordinate: CLLocationCoordinate2D) -> String {
        return String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
    }
}

// MARK: - Error Types
extension EventViewModel {
    enum EventError: LocalizedError {
        case locationNotAvailable
        case networkError(Error)
        case noEventsFound
        
        var errorDescription: String? {
            switch self {
            case .locationNotAvailable:
                return "Location services are not available"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .noEventsFound:
                return "No events found in your area"
            }
        }
    }
}

// MARK: - Preview Helper
extension EventViewModel {
    static var preview: EventViewModel {
        let locationService = LocationService()
        let authViewModel = AuthViewModel()
        let favoritesManager = FavoritesManager(authViewModel: authViewModel)
        return EventViewModel(locationService: locationService, favoritesManager: favoritesManager)
    }
}
