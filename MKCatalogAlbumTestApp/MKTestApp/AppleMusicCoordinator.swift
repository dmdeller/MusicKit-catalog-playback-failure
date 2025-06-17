//
//  AppleMusicCoordinator.swift
//  MKTestApp
//
//  Created by David Deller on 5/20/25.
//

import Foundation
import MusicKit

@MainActor
class AppleMusicCoordinator: ObservableObject {
    enum Error: Swift.Error, LocalizedError {
        case authorizationDenied
        case authorizationRestricted
        case authorizationUnknown
        case tooManyAttempts
        case otherError(Swift.Error)
        
        static let appName = "MKTestApp"
        
        var errorDescription: String? {
            switch self {
            case .authorizationDenied:
                "\(Self.appName) can’t access Apple Music because permission was denied. If you want to use Apple Music with \(Self.appName), go to System Settings > Privacy & Security > Media & Apple Music, find \(Self.appName) in the list, and toggle the switch on."
            case .authorizationRestricted:
                "\(Self.appName) can’t access Apple Music because of system settings. This may be due to the way this device was originally set up. If this device belongs to a workplace or school, please contact your system administrator. Otherwise, please contact \(Self.appName) support."
            case .authorizationUnknown, .tooManyAttempts:
                "\(Self.appName) can’t access Apple Music because of an unknown problem. Please check the App Store to see if there is a new version of \(Self.appName) available, and update the app if possible. If the problem persists, please contact \(Self.appName) support."
            case .otherError(let error):
                error.localizedDescription
            }
        }
    }
    
    static let shared = AppleMusicCoordinator()
    
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined
    
    var authorizationError: Error? {
        switch authorizationStatus {
        case .notDetermined:
            nil
        case .denied:
            .authorizationDenied
        case .restricted:
            .authorizationRestricted
        case .authorized:
            nil
        @unknown default:
            .authorizationUnknown
        }
    }
    
    @discardableResult func requestAccess() async -> MusicAuthorization.Status {
        authorizationStatus = await MusicAuthorization.request()
        return authorizationStatus
    }
    
    func verifyAccess(_ count: Int = 1) async throws {
        let maxRecursion = 3
        
        if count >= maxRecursion {
            // Prevent infinite recursion
            throw Error.tooManyAttempts
        }
        
        switch authorizationStatus {
        case .notDetermined:
            await requestAccess()
            try await verifyAccess(count + 1)
        case .denied:
            throw Error.authorizationDenied
        case .restricted:
            throw Error.authorizationRestricted
        case .authorized:
            return
        @unknown default:
            throw Error.authorizationUnknown
        }
    }
}
