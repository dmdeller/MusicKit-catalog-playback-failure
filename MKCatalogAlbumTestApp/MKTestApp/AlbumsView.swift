//
//  AlbumsView.swift
//  MKTestApp
//
//  Created by David Deller on 5/20/25.
//

import SwiftUI
import OSLog
import MusicKit

struct AlbumsView: View {
    // MARK: - Types
    
    enum Error: Swift.Error, LocalizedError {
        case emptyAlbum
        case otherError(Swift.Error)
        
        var errorDescription: String? {
            switch self {
            case .emptyAlbum:
                "The album doesn't contain any songs"
            case .otherError(let error):
                error.localizedDescription
            }
        }
    }
    
    // MARK: - Properties
    
    let ignoreErrors: Bool
    
    let player = ApplicationMusicPlayer.shared
    
    @ObservedObject private var appleMusicCoordinator: AppleMusicCoordinator = .shared
    
    @State private var albums: [Album] = []
    @State private var status: String = "Waiting for search input"
    @State private var playingAlbum: Album?
    
    @State private var searchText: String = ""
    
    @State private var isReloadAllowed = false
    @State private var activityCount = 0
    
    @State private var inlineError: Swift.Error?
    @State private var modalError: Error?
    
    // MARK: - Init
    
    init(ignoreErrors: Bool = false) {
        self.ignoreErrors = ignoreErrors
    }
    
    // MARK: - Views
    
    var body: some View {
        Group {
            if let authError = appleMusicCoordinator.authorizationError {
                errorView(error: authError)
            } else if let inlineError {
                errorView(error: inlineError)
            } else {
                VStack(spacing: 0) {
                    if albums.isEmpty {
                        welcomeView
                    } else {
                        listView
                    }
                    
                    Divider()
                    
                    statusView
                }
            }
        }
        .task {
            await appleMusicCoordinator.requestAccess()
        }
        .onDisappear {
            resetActivityCount()
        }
        .alert(isPresented: .valueToBoolean($modalError), error: modalError, actions: {
            Button("OK") {}
        })
        .toolbar {
            if activityCount > 0 {
                ProgressView()
                    .controlSize(.small)
            }
            
            Button("Reload", systemImage: "arrow.counterclockwise") {
                reload()
            }
            .disabled(!isReloadAllowed)
            
            Button("Stop", systemImage: "stop.fill") {
                player.stop()
            }
        }
        .searchable(text: $searchText, prompt: "Search catalog for albums")
        .onSubmit(of: .search) {
            reload()
        }
    }
    
    @ViewBuilder
    private var welcomeView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("This sample app demonstrates an issue with MusicKit in which some tracks from some albums will not play. The app adds all tracks from the album to the queue, but some of them may silently disappear and not be played. Please see the full explanation on the Feedback.")
            
            Text("Note: Make sure this app is registered in Certificates, Identifiers & Profiles with MusicKit service enabled, or it won't work!")
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var listView: some View {
        List {
            ForEach(albums) { album in
                albumView(album)
            }
        }
    }
    
    @ViewBuilder
    private var statusView: some View {
        VStack(spacing: 10) {
            if let album = playingAlbum, let song = album.tracks?.first {
                Text("Should be playing: " + song.title + " - track # \(song.trackNumber.flatMap { String($0) } ?? "?")")
            }
            if let entry = player.queue.currentEntry, case .song(let song) = entry.item {
                Text("Actually playing: " + entry.title + " - track # \(song.trackNumber.flatMap { String($0) } ?? "?")")
            }
            Text("Status: " + status)
        }
        .padding(6)
    }
    
    @ViewBuilder
    private func albumView(_ album: Album) -> some View {
        HStack {
            if album.artistName.isEmpty {
                Text(album.title)
            } else {
                Text("\(album.artistName) — \(album.title)")
            }
            
            Spacer()
            
            Button("Play") {
                play(album: album)
            }
        }
    }
    
    @ViewBuilder
    private func errorView(error: Swift.Error) -> some View {
        VStack {
            Text(error.localizedDescription)
        }
    }
    
    // MARK: - Actions
    
    private func play(album: Album) {
        Task {
            do {
                let albumWithTracks = try await album.with(.tracks, preferredSource: .catalog)
                guard let songs = albumWithTracks.songs else { throw Error.emptyAlbum }
                
                let beforeCount = songs.count
                
                let entries = songs.map { MusicPlayer.Queue.Entry($0) }
                player.queue = .init(entries)
                
                if !player.isPreparedToPlay {
                    try await player.prepareToPlay()
                }
                
                try await player.play()
                
                let afterCount = player.queue.entries.count
                
                self.status = "\(beforeCount) songs added; \(afterCount) songs actually in queue - \(beforeCount == afterCount ? "correct behavior" : "MISMATCH DETECTED")"
                self.playingAlbum = albumWithTracks
            } catch {
                handleModalError(error)
            }
        }
    }
    
    // MARK: - Loading
    
    private func reload() {
        isReloadAllowed = false
        removeInlineError()
        incrementActivityCount()
        
        Task {
            defer {
                decrementActivityCount()
            }
            do {
                var request = MusicCatalogSearchRequest(
                    term: searchText,
                    types: [Album.self]
                )
                
                request.includeTopResults = false
                request.limit = 20
                
                let response = try await request.response()
                self.albums = Array(response.albums)
                
                self.status = "Got \(albums.count) albums"
            } catch {
                handleInlineError(error)
            }
        }
    }
    
    // MARK: - Activity count
    
    private func incrementActivityCount() {
        activityCount += 1
        isReloadAllowed = false
    }
    
    private func decrementActivityCount() {
        activityCount -= 1
        isReloadAllowed = activityCount == 0
    }
    
    private func resetActivityCount() {
        activityCount = 0
        isReloadAllowed = true
    }
    
    // MARK: - Errors
    
    private func handleInlineError(_ error: Swift.Error) {
        guard !ignoreErrors else { return }
        inlineError = error
    }
    
    private func removeInlineError() {
        inlineError = nil
    }
    
    func handleModalError(_ error: Swift.Error) {
        if let localError = error as? Error {
            modalError = localError
        } else {
            modalError = Error.otherError(error)
        }
    }
    
    private func removeModalError() {
        modalError = nil
    }
}

#Preview {
    AlbumsView(ignoreErrors: true)
}
