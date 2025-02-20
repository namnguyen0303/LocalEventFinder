//
//  Extensions.swift
//  LocalEventFinder
//
//  Created by Nam Nguyen on 11/26/24.
//

import Foundation

extension Date {
    func formatForDisplay() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}
