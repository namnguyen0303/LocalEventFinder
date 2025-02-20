//
//  FavoritesManager.swift
//  LocalEventFinder
//
//  Created by Nam Nguyen on 12/2/24.
//

import Foundation
import FirebaseFirestore

@MainActor
class FavoritesManager: ObservableObject {
    @Published var favoriteEvents: [String] = []
    private let authViewModel: AuthViewModel
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        self.favoriteEvents = authViewModel.user?.favorites ?? []
        
        // Add observer for user changes
        Task {
            for await _ in authViewModel.$user.values {
                self.favoriteEvents = authViewModel.user?.favorites ?? []
            }
        }
    }
    
    func toggleFavorite(for event: Event) async {
        let updatedFavorites = favoriteEvents.contains(event.id)
            ? favoriteEvents.filter { $0 != event.id }
            : favoriteEvents + [event.id]
        
        do {
            try await authViewModel.updateUserFavorites(updatedFavorites)
            self.favoriteEvents = updatedFavorites
        } catch {
            print("Error updating favorites: \(error.localizedDescription)")
        }
    }
    
    func isFavorite(_ eventId: String) -> Bool {
        favoriteEvents.contains(eventId)
    }
    
    // Add this method to update events with favorite status
    func updateEventsWithFavoriteStatus(_ events: [Event]) -> [Event] {
        events.map { event in
            var updatedEvent = event
            updatedEvent.isFavorite = isFavorite(event.id)
            return updatedEvent
        }
    }
}
