//
//  Extensions.swift
//  MKTestApp
//
//  Created by David Deller on 5/20/25.
//

import Foundation
import SwiftUI
import MusicKit
import OSLog

extension Binding {
    static func valueToBoolean<OriginalValue>(_ original: Binding<OriginalValue?>) -> Binding<Bool> {
        Binding<Bool>(
            get: {
                original.wrappedValue != nil
            },
            set: { newValue in
                let log = Logger.utility
                
                if newValue {
                    assertionFailure("Unable to translate true result into value")
                    log.error("Unable to translate true result into value")
                }
                
                original.wrappedValue = nil
            }
        )
    }
}

extension Album {
    var songs: [Song]? {
        tracks?
            .compactMap {
                if case .song(let song) = $0 {
                    return song
                } else {
                    return nil
                }
            }
    }
    
    var durationOfSongs: TimeInterval? {
        songs?.compactMap(\.duration).reduce(0, +)
    }
}
