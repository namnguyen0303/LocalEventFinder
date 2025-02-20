//
//  EventDetailView.swift
//  LocalEventFinder
//
//  Created by Nam Nguyen on 11/26/24.
//

import Foundation
import SwiftUI
import MapKit
import UserNotifications

struct EventDetailView: View {
    let event: Event
    @ObservedObject var favoritesManager: FavoritesManager
    @State private var showingMapOptions = false
    @State private var showingReminderAlert = false
    @State private var hasReminder = false
    
    private var coordinate: CLLocationCoordinate2D? {
        guard let lat = Double(event.venue.latitude ?? ""),
              let lon = Double(event.venue.longitude ?? "") else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Event Header Section
                VStack(alignment: .leading, spacing: 16) {
                    // Event Type Badge
                    Text(event.eventType)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                    
                    // Title and Favorite
                    HStack(alignment: .top) {
                        Text(event.name.text)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: {
                            Task {
                                await favoritesManager.toggleFavorite(for: event)
                            }
                        }) {
                            Image(systemName: favoritesManager.isFavorite(event.id) ? "heart.fill" : "heart")
                                .foregroundColor(favoritesManager.isFavorite(event.id) ? .red : .gray)
                                .font(.title2)
                        }
                    }
                }
                
                Divider()
                
                // Date and Time Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Date & Time", systemImage: "calendar")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        if let startDate = formatDate(event.start.local) {
                            Text(startDate)
                                .font(.subheadline)
                        }
                        if let endDate = formatDate(event.end.local) {
                            Text("Until \(endDate)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.leading, 28)
                }
                
                Divider()
                
                // Venue Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Location", systemImage: "mappin.circle.fill")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(event.venue.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if let address = event.venue.address.localized_address_display {
                            Text(address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.leading, 28)
                    
                    // Map
                    if let coordinate = coordinate {
                        Button(action: {
                            showingMapOptions = true
                        }) {
                            Map(position: .constant(.region(MKCoordinateRegion(
                                center: coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )))) {
                                Marker(event.venue.name, coordinate: coordinate)
                            }
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Divider()
                
                // Reminder Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Reminder", systemImage: "bell.fill")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Button {
                        if hasReminder {
                            removeReminders()
                        } else {
                            showingReminderAlert = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: hasReminder ? "bell.slash.fill" : "bell.badge.fill")
                                .foregroundColor(hasReminder ? .red : .blue)
                            Text(hasReminder ? "Remove Reminder" : "Set Event Reminder")
                                .foregroundColor(hasReminder ? .red : .blue)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(hasReminder ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding(.leading, 28)
                }
                
                Divider()
                
                // Description Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("About", systemImage: "info.circle.fill")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(event.description.text)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.leading, 28)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Open in Maps",
            isPresented: $showingMapOptions,
            titleVisibility: .visible
        ) {
            Button("Apple Maps") {
                openInAppleMaps(coordinate: coordinate!, name: event.venue.name)
            }
            
            Button("Google Maps") {
                openInGoogleMaps(coordinate: coordinate!, name: event.venue.name)
            }
            
            Button("Cancel", role: .cancel) {}
        }
        .alert("Set Reminder", isPresented: $showingReminderAlert) {
            Button("30 minutes before") { addReminder(hours: 0.5) }
            Button("1 hour before") { addReminder(hours: 1) }
            Button("3 hours before") { addReminder(hours: 3) }
            Button("1 day before") { addReminder(hours: 24) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("When would you like to be reminded?")
        }
        .onAppear {
            checkExistingReminders()
        }
    }
    
    private func formatDate(_ dateString: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        guard let date = dateFormatter.date(from: dateString) else {
            return nil
        }
        
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
    
    private func openInAppleMaps(coordinate: CLLocationCoordinate2D, name: String) {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    private func openInGoogleMaps(coordinate: CLLocationCoordinate2D, name: String) {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "comgooglemaps://?q=\(encodedName)&center=\(coordinate.latitude),\(coordinate.longitude)&zoom=15"
        
        if let url = URL(string: urlString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // If Google Maps app is not installed, open in browser
                let webUrlString = "https://www.google.com/maps/search/?api=1&query=\(coordinate.latitude),\(coordinate.longitude)"
                if let webUrl = URL(string: webUrlString) {
                    UIApplication.shared.open(webUrl)
                }
            }
        }
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return dateFormatter.date(from: dateString)
    }
    
    private func addReminder(hours: Double) {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Event: \(event.name.text)"
        content.body = """
        Starting \(hours == 1 ? "in 1 hour" : "in \(hours) hours")
        At: \(event.venue.name)
        """
        content.sound = .default
        
        if let date = parseDate(event.start.local) {
            let triggerDate = date.addingTimeInterval(-Double(hours * 3600))
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: triggerDate
            )
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "event-\(event.id)",
                content: content,
                trigger: trigger
            )
            
            center.add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                } else {
                    print("Reminder set successfully for \(hours) hours before event")
                    hasReminder = true
                }
            }
        }
    }
    
    private func removeReminders() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["event-\(event.id)"])
        hasReminder = false
    }
    
    private func checkExistingReminders() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                hasReminder = requests.contains { $0.identifier == "event-\(event.id)" }
            }
        }
    }
}
