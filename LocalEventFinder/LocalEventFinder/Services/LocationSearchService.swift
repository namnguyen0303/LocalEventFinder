//
//  LocationSearchService.swift
//  LocalEventFinder
//
//  Created by Nam Nguyen on 12/2/24.
//

import Foundation
import MapKit

class LocationSearchService: NSObject, ObservableObject {
    @Published var searchResults: [MKLocalSearchCompletion] = []
    private let searchCompleter = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
    }
    
    func searchLocation(_ query: String) {
        searchCompleter.queryFragment = query
    }
    
    func getCoordinates(for result: MKLocalSearchCompletion) async throws -> CLLocationCoordinate2D {
        let searchRequest = MKLocalSearch.Request(completion: result)
        let search = MKLocalSearch(request: searchRequest)
        let response = try await search.start()
        
        guard let coordinate = response.mapItems.first?.placemark.coordinate else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Location not found"])
        }
        
        return coordinate
    }
}

extension LocationSearchService: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.searchResults = completer.results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Location search error: \(error.localizedDescription)")
    }
}
