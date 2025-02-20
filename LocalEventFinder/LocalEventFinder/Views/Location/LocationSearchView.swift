//
//  LocationSearchView.swift
//  LocalEventFinder
//
//  Created by Nam Nguyen on 12/2/24.
//

import Foundation
import SwiftUI
import MapKit

struct SearchBarView: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search locations...", text: $text)
                .autocorrectionDisabled()
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct LocationSearchView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var searchService = LocationSearchService()
    @ObservedObject var locationService: LocationService
    @Binding var searchRadius: Int
    @State private var searchText = ""
    
    let radiusOptions = [5, 10, 25, 50, 100]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBarView(text: $searchText)
                    .onChange(of: searchText) { _, newValue in
                        searchService.searchLocation(newValue)
                    }
                
                if searchText.isEmpty {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Search Radius Section
                            VStack(alignment: .leading, spacing: 10) {
                                Text("SEARCH RADIUS")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                Menu {
                                    Picker("Radius", selection: $searchRadius) {
                                        ForEach(radiusOptions, id: \.self) { miles in
                                            Text("\(miles) miles").tag(miles)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text("Radius (miles)")
                                        Spacer()
                                        Text("\(searchRadius) miles")
                                            .foregroundColor(.secondary)
                                        Image(systemName: "chevron.up.chevron.down")
                                            .foregroundColor(.secondary)
                                            .imageScale(.small)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                }
                                .padding(.horizontal)
                            }
                            
                            // Current Location Section
                            // Current Location Section
                            if locationService.location != nil {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("CURRENT LOCATION")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                    
                                    VStack(spacing: 16) {
                                        // Address View
                                        if let placemark = locationService.currentPlacemark {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(formatAddress(placemark))
                                                    .font(.system(size: 15))
                                                
                                                Text("Current Location")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Popular Cities Section
                            SuggestedLocationsView(
                                searchService: searchService,
                                locationService: locationService,
                                dismiss: dismiss
                            )
                        }
                        .padding(.vertical)
                    }
                } else {
                    List(searchService.searchResults, id: \.self) { result in
                        Button {
                            Task {
                                await selectLocation(result)
                            }
                        } label: {
                            VStack(alignment: .leading) {
                                Text(result.title)
                                    .foregroundColor(.primary)
                                Text(result.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Location Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
    
    private func selectLocation(_ result: MKLocalSearchCompletion) async {
        do {
            let coordinate = try await searchService.getCoordinates(for: result)
            locationService.setManualLocation(coordinate)
            dismiss()
        } catch {
            print("Error setting location: \(error.localizedDescription)")
        }
    }
    
    private func formatAddress(_ placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        
        if let locality = placemark.locality {
            components.append(locality)
        }
        
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        if let postalCode = placemark.postalCode {
            components.append(postalCode)
        }
        
        return components.isEmpty ? "Location Unknown" : components.joined(separator: ", ")
    }
}

struct SuggestedLocationsView: View {
    let searchService: LocationSearchService
    let locationService: LocationService
    let dismiss: DismissAction
    
    let suggestions = [
        ("New York", "🗽", (40.7128, -74.0060)),
        ("Los Angeles", "🌴", (34.0522, -118.2437)),
        ("Chicago", "🌆", (41.8781, -87.6298)),
        ("Miami", "🏖", (25.7617, -80.1918)),
        ("Las Vegas", "🎰", (36.1699, -115.1398))
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("POPULAR CITIES")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(suggestions, id: \.0) { city, emoji, coordinates in
                        CityButton(
                            city: city,
                            emoji: emoji,
                            action: {
                                locationService.setManualLocation(
                                    CLLocationCoordinate2D(
                                        latitude: coordinates.0,
                                        longitude: coordinates.1
                                    )
                                )
                                dismiss()
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }
}

struct CityButton: View {
    let city: String
    let emoji: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text(emoji)
                    .font(.system(size: 40))
                Text(city)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

#Preview {
    LocationSearchView(
        locationService: LocationService(),
        searchRadius: .constant(10)
    )
}
