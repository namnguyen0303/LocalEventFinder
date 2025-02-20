//
//  EventRowView.swift
//  LocalEventFinder
//
//  Created by Nam Nguyen on 11/26/24.
//

import Foundation
import SwiftUI

struct EventRowView: View {
    let event: Event
    @ObservedObject var favoritesManager: FavoritesManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name.text)
                    .font(.headline)
                    .lineLimit(1)
                Text(event.venue.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(formatDate(event.start.local))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    await favoritesManager.toggleFavorite(for: event)
                }
            }) {
                Image(systemName: favoritesManager.isFavorite(event.id) ? "heart.fill" : "heart")
                    .foregroundColor(favoritesManager.isFavorite(event.id) ? .red : .gray)
                    .font(.title3)
            }
        }
        .padding(.vertical, 8)
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

