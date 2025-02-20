//
//  EventListView.swift
//  LocalEventFinder
//
//  Created by Nam Nguyen on 11/26/24.
//

import Foundation
import SwiftUI
import CoreLocation

struct EventListView: View {
    @StateObject private var locationService = LocationService()
    @StateObject private var viewModel: EventViewModel
    @StateObject private var favoritesManager: FavoritesManager
    @State private var showingLocationSearch = false
    @State private var showingFavoritesOnly = false
    @State private var isInitialLoad = true
    @State private var selectedEventType: String = "All"
    @State private var searchText = ""
    
    let eventTypes = ["All", "Music", "Sports", "Arts & Theatre"]  // Added
    
    init() {
        let locationService = LocationService()
        let authViewModel = AuthViewModel()
        let favoritesManager = FavoritesManager(authViewModel: authViewModel)
        
        _locationService = StateObject(wrappedValue: locationService)
        _favoritesManager = StateObject(wrappedValue: favoritesManager)
        _viewModel = StateObject(wrappedValue: EventViewModel(
            locationService: locationService,
            favoritesManager: favoritesManager
        ))
    }
    
    var filteredEvents: [Event] {
        // First filter: Favorites
        let events = showingFavoritesOnly
            ? viewModel.events.filter { favoritesManager.isFavorite($0.id) }
            : viewModel.events
        
        // Second filter: Event Type
        let typeFiltered = selectedEventType == "All" ? events : events.filter { $0.isEventType(selectedEventType) }
        
        // Third filter: Search Text
        if searchText.isEmpty {
            return typeFiltered
        }
        
        return typeFiltered.filter {
            $0.name.text.localizedCaseInsensitiveContains(searchText) ||
            $0.venue.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
            NavigationView {
                ZStack {
                    // Background color
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()
                    
                    if locationService.errorMessage != nil {
                        LocationErrorView(errorMessage: locationService.errorMessage ?? "")
                    } else if locationService.location == nil {
                        RequestLocationView(locationService: locationService)
                    } else {
                        VStack(spacing: 0) {
                            // Event Type Filter
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(eventTypes, id: \.self) { type in
                                        FilterChip(
                                            title: type,
                                            isSelected: selectedEventType == type,
                                            action: { selectedEventType = type }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical, 8)
                            
                            if filteredEvents.isEmpty && !viewModel.isLoading {
                                NoEventsView(showingFavoritesOnly: showingFavoritesOnly)
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 16) {
                                        ForEach(filteredEvents) { event in
                                            NavigationLink(destination: EventDetailView(event: event, favoritesManager: favoritesManager)) {
                                                EventCardView(event: event, favoritesManager: favoritesManager)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .task {
                                                await viewModel.loadMoreEventsIfNeeded(currentEvent: event)
                                            }
                                        }
                                    }
                                    .padding()
                                }
                                .refreshable {
                                    await refreshEvents()
                                }
                            }
                        }
                        .overlay {
                            if viewModel.isLoading && isInitialLoad {
                                LoadingView()
                            }
                        }
                    }
                }
            .navigationTitle("Local Events")
            .searchable(text: $searchText, prompt: "Search events")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: {
                            showingFavoritesOnly.toggle()
                        }) {
                            Image(systemName: showingFavoritesOnly ? "heart.fill" : "heart")
                                .foregroundColor(showingFavoritesOnly ? .red : .gray)
                        }
                        
                        Button(action: {
                            showingLocationSearch = true
                        }) {
                            Image(systemName: "mappin.and.ellipse")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingLocationSearch) {
                LocationSearchView(
                    locationService: locationService,
                    searchRadius: $viewModel.searchRadius
                )
            }
            .onAppear {
                if isInitialLoad {
                    locationService.startUpdatingLocation()
                    Task {
                        await refreshEvents()
                    }
                }
            }
            .onChange(of: locationService.location) { _, _ in
                Task {
                    await refreshEvents()
                }
            }
            .onChange(of: viewModel.searchRadius) { _, _ in
                Task {
                    await refreshEvents()
                }
            }
            .onChange(of: showingLocationSearch) { _, newValue in
                if !newValue {  // Sheet was dismissed
                    Task {
                        await refreshEvents()
                    }
                }
            }
        }
    }
    
    private func refreshEvents() async {
        isInitialLoad = false
        await viewModel.fetchNearbyEvents()
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                    Color.blue.opacity(0.1) :
                    Color(.systemGray6)
                )
                .foregroundColor(
                    isSelected ?
                    .blue :
                    .primary
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ?
                            Color.blue.opacity(0.3) :
                            Color.clear,
                            lineWidth: 1
                        )
                )
        }
    }
}

struct EventCardView: View {
    let event: Event
    @ObservedObject var favoritesManager: FavoritesManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Event Type Badge and Favorite Button
            HStack {
                Text(event.eventType)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
                    .foregroundColor(.blue)
                
                Spacer()
                
                Button {
                    Task {
                        await favoritesManager.toggleFavorite(for: event)
                    }
                } label: {
                    Image(systemName: favoritesManager.isFavorite(event.id) ? "heart.fill" : "heart")
                        .foregroundColor(favoritesManager.isFavorite(event.id) ? .red : .gray)
                }
            }
            
            // Event Title
            Text(event.name.text)
                .font(.headline)
                .lineLimit(2)
            
            // Venue and Date Info
            VStack(alignment: .leading, spacing: 8) {
                // Venue
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.blue)
                    Text(event.venue.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Date
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text(formatDate(event.start.local))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        guard let date = dateFormatter.date(from: dateString) else {
            return dateString
        }
        
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)
            
            Text("Finding events near you...")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("This may take a moment")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).opacity(0.9))
    }
}

struct LocationErrorView: View {
    let errorMessage: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.slash")
                .font(.largeTitle)
            Text(errorMessage)
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        }
        .padding()
    }
}

struct RequestLocationView: View {
    let locationService: LocationService
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.circle")
                .font(.system(size: 50))
            Text("Location Access Required")
                .font(.title2)
            Text("Please enable location access to find events near you")
                .multilineTextAlignment(.center)
            Button("Enable Location Access") {
                locationService.requestPermission()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

struct NoEventsView: View {
    let showingFavoritesOnly: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: showingFavoritesOnly ? "heart.slash" : "calendar.badge.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text(showingFavoritesOnly ? "No favorite events" : "No events found nearby")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(showingFavoritesOnly ? "Add some favorites!" : "Try adjusting your search radius")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if !showingFavoritesOnly {
                Button(action: {
                    // Action to open location search
                }) {
                    Label("Adjust Search Area", systemImage: "location.circle.fill")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }
}

#Preview {
    EventListView()
}
